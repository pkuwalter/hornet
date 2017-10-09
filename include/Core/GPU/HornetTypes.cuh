/**
 * @brief High-level API to access to cuStinger data (Vertex, Edge)
 * @author Federico Busato                                                  <br>
 *         Univerity of Verona, Dept. of Computer Science                   <br>
 *         federico.busato@univr.it
 * @date August, 2017
 * @version v2
 *
 * @copyright Copyright © 2017 Hornet. All rights reserved.
 *
 * @license{<blockquote>
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * * Redistributions of source code must retain the above copyright notice, this
 *   list of conditions and the following disclaimer.
 * * Redistributions in binary form must reproduce the above copyright notice,
 *   this list of conditions and the following disclaimer in the documentation
 *   and/or other materials provided with the distribution.
 * * Neither the name of the copyright holder nor the names of its
 *   contributors may be used to endorse or promote products derived from
 *   this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 * </blockquote>}
 *
 * @file
 */
#pragma once

#include "BasicTypes.hpp"                        //vid_t
#include "Core/DataLayout/DataLayoutDev.cuh"

namespace hornet {
namespace gpu {

template<typename, typename> class Vertex;
template<typename, typename> class Edge;
template<typename, typename> class HornetDevice;

template<typename... VertexTypes, typename... EdgeTypes>
class Vertex<TypeList<VertexTypes...>, TypeList<EdgeTypes...>> :
                                 public AoSData<size_t, void*, VertexTypes...> {
    template<typename T, typename R> friend class Edge;
    template<typename T, typename R> friend class HornetDevice;

    static const int NUM_ETYPES = sizeof...(EdgeTypes) + 1;

    using         EdgeT = Edge<TypeList<VertexTypes...>,
                               TypeList<EdgeTypes...>>;
    using HornetDeviceT = HornetDevice<TypeList<VertexTypes...>,
                                       TypeList<EdgeTypes...>>;
    using       WeightT = IndexT<1, NUM_ETYPES, vid_t, EdgeTypes...>;

    using   EdgesLayout = BestLayoutDevPitch<PITCH<EdgeTypes...>,
                                             vid_t, EdgeTypes...>;
    using edgeit_t = typename HornetDeviceT::edgeit_t;
public:
    /**
     * @brief id of the vertex
     * @return id of the vertex
     */
    __device__ __forceinline__
    vid_t id() const;

    /**
     * @brief degree of the vertex
     * @return degree of the vertex
     */
    __device__ __forceinline__
    degree_t degree() const;

    /**
     *
     */
    __device__ __forceinline__
    degree_t limit() const;

    __device__ __forceinline__
    edgeit_t edge_begin() const;

    __device__ __forceinline__
    edgeit_t edge_end() const;

    /**
     * @brief Get an edge associeted to the vertex
     * @param[in] index index of the edge
     * @return edge at index `index`
     * @warning `index` must be in the range \f$0 \le index < degree\f$.
     * The behavior is undefined otherwise.
     */
    __device__ __forceinline__
    EdgeT edge(degree_t index) const;

    /**
     * @internal
     * @brief pointer to the device degree location
     * @return pointer to the device degree location
     */
    __device__ __forceinline__
    size_t* degree_ptr() const;

    __device__ __forceinline__
    void set_degree(size_t degree);

    __device__ __forceinline__
    vid_t* neighbor_ptr() const;

    __device__ __forceinline__
    vid_t neighbor_id(degree_t index) const;

    /**
     * @brief  value of a user-defined vertex field
     * @tparam INDEX index of the user-defined vertex field to return
     * @return value of the user-defined vertex field at the index `INDEX`
     *         (type at the index `INDEX` in the `EdgeTypes` list)
     * @remark the method does not compile if the `VertexTypes` list does not
     *         contain atleast `INDEX` fields
     * @details **Example:**
     * @code{.cpp}
     *      auto vertex_label = vertex.field<0>();
     * @endcode
     */
    template<int INDEX>
    __device__ __forceinline__
    typename xlib::SelectType<INDEX, VertexTypes...>::type
    field() const;

    /**
     * @brief Store an edge at a specific position in the adjacency array
     * @param[in] edge Edge to store
     * @param[in] pos Position where substite the edge
     */
    __device__ __forceinline__
    void store(degree_t pos, const EdgeT& edge);

private:
    HornetDeviceT& _hornet;
    vid_t          _id;

    /**
     * @internal
     * @brief Default costructor
     * @param[in] data cuStinger device data
     */
    __device__ __forceinline__
    Vertex(HornetDeviceT& data, vid_t index = static_cast<vid_t>(-1));
};

//==============================================================================

template<typename... VertexTypes, typename... EdgeTypes>
class Edge<TypeList<VertexTypes...>, TypeList<EdgeTypes...>> :
                                           public AoSData<vid_t, EdgeTypes...> {
    template<typename T, typename R> friend class Vertex;

    using       VertexT = Vertex<TypeList<VertexTypes...>,
                                 TypeList<EdgeTypes...>>;
    using HornetDeviceT = HornetDevice<TypeList<VertexTypes...>,
                                       TypeList<EdgeTypes...>>;

    using   EdgesLayout = BestLayoutDevPitch<PITCH<EdgeTypes...>,
                                             vid_t, EdgeTypes...>;

    static const int NUM_ETYPES = sizeof...(EdgeTypes) + 1;
    using     WeightT = IndexT<1, NUM_ETYPES, vid_t, EdgeTypes...>;
    using TimeStamp1T = IndexT<2, NUM_ETYPES, vid_t, EdgeTypes...>;
    using TimeStamp2T = IndexT<3, NUM_ETYPES, vid_t, EdgeTypes...>;
public:
    /**
     * @brief source of the edge
     * @return source of the edge
     */
    __device__ __forceinline__
    vid_t src_id() const;

    /**
     * @brief destination of the edge
     * @return destination of the edge
     */
    __device__ __forceinline__
    vid_t dst_id() const;

    /**
     * @brief Source vertex of the edge
     * @return Source vertex
     */
    __device__ __forceinline__
    VertexT src() const;

    /**
     * @brief Destination vertex of the edge
     * @return Destination vertex
     */
    __device__ __forceinline__
    VertexT dst() const;

    /**
     * @brief weight of the edge (if it exists)
     * @return weight of the edge (first `EdgeTypes` type)
     * @remark the method is disabled if the `EdgeTypes` list does not contain
     *         atleast one field
     * @details **Example:**
     * @code{.cpp}
     *      auto edge_weight = edge.weight();
     * @endcode
     */
    template<typename = EnableT>
    __device__ __forceinline__
    WeightT weight() const;

    template<typename = EnableT>
    __device__ __forceinline__
    void set_weight(WeightT weight);

    /**
     * @brief first time stamp of the edge
     * @return first time stamp of the edge (second `EdgeTypes` type)
     * @remark the method is disabled if the `EdgeTypes` list does not contain
     *         atleast two fields
     */
    template<typename = EnableT>
    __device__ __forceinline__
    TimeStamp1T time_stamp1() const;

    /**
     * @brief second time stamp of the edge
     * @return second time stamp of the edge (third `EdgeTypes` list type)
     * @remark the method is disabled if the `EdgeTypes` list does not contain
     *         atleast three fields
     */
    template<typename = EnableT>
    __device__ __forceinline__
    TimeStamp2T time_stamp2() const;

    /**
     * @brief  value of a user-defined edge field
     * @tparam INDEX index of the user-defined edge field to return
     * @return value of the user-defined edge field at the index `INDEX`
     *         (type at the index `INDEX` in the `EdgeTypes` list)
     * @remark the method does not compile if the `EdgeTypes` list does not
     *         contain atleast `INDEX` fields
     * @details **Example:**
     * @code{.cpp}
     * Edge edge = ...
     *      auto edge_label = edge.field<0>();
     * @endcode
     */
    template<int INDEX>
    __device__ __forceinline__
    typename xlib::SelectType<INDEX, EdgeTypes...>::type
    field() const;

private:
    HornetDeviceT& _hornet;
    void*          _ptr;
    vid_t          _src_id;

    /**
     * @internal
     * @brief Default Costrustor
     * @param[in] block_ptr pointer in the *block* to the edge
     * @param[in] index index of the edge in the adjacency array
     * @param[in] size of the *block*
     */
    __device__ __forceinline__
    Edge(HornetDeviceT& hornet,
         void*          edge_ptr,
         vid_t          src_id = static_cast<vid_t>(-1),
         void*          ptr    = nullptr);
};

} // namespace gpu
} // namespace hornet

#include "impl/HornetTypes.i.cuh"
