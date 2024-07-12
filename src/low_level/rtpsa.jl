"""
    `TPS`

This is a 1-to-1 struct for the C definition `tpsa` (real TPSA) in GTPSA.

### Fields
- `d::Ptr{Cvoid}`             -- Ptr to tpsa descriptor
- `lo::Cuchar`                -- lowest used ord
- `hi::Cuchar`                -- highest used ord
- `mo::Cuchar`                -- max ord
- `ao::Cuchar`                -- allocated order
- `uid::Cint`                 -- Special user field for external use (and padding)
- `nam::NTuple{NAMSZ,Cuchar}` -- tpsa name max string length 15 chars NAMSZ
- `coef::Ptr{Cdouble}`        -- warning: must be identical to ctpsa up to coef excluded                                                                                                  
"""
mutable struct TPS{T<:Union{Float64,ComplexF64}} <: Number 
  d::Ptr{Desc}                                       
  lo::UInt8                
  hi::UInt8     
  mo::UInt8  
  ao::UInt8
  uid::Cint            
  nam::NTuple{NAMSZ,UInt8} 
  coef::Ptr{T}     
  
  # Analog to C code mad_tpsa_newd
  function TPS{T}(d::Ptr{Desc}, mo::UInt8) where {T}
    mo = min(mo, unsafe_load(d).mo)
    sz = unsafe_load(unsafe_load(d).ord2idx, mo+2)*sizeof(T)
    coef = @ccall jl_malloc(sz::Csize_t)::Ptr{T}
    ao = mo
    uid = Cint(0)
    nam = (0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0)
    lo = 0x1
    hi = 0x0
    unsafe_store!(coef, T(0))

    t = new{T}(d, lo, hi, mo, ao, uid, name, coef)

    f(t) = @ccall jl_free(t.coef::Ptr{Cvoid})::Cvoid
    finalizer(f, t)

    return t
  end
end

"""
    mad_tpsa_newd(d::Ptr{Desc}, mo::Cuchar)::Ptr{TPS}

Creates a TPSA defined by the specified descriptor and maximum order. If `MAD_TPSA_DEFAULT` 
is passed for `mo`, the `mo` defined in the descriptor is used. If `mo > d_mo`, then `mo = d_mo`.

### Input
- `d`  -- Descriptor
- `mo` -- Maximum order

### Output
- `t`  -- New TPSA defined by the descriptor
"""
function mad_tpsa_newd(d::Ptr{Desc}, mo::Cuchar)::Ptr{TPS}
  t = @ccall MAD_TPSA.mad_tpsa_newd(d::Ptr{Desc}, mo::Cuchar)::Ptr{TPS}
  return t
end


"""
    mad_tpsa_new(t::Ptr{TPS}, mo::Cuchar)::Ptr{TPS}

Creates a blank TPSA with same number of variables/parameters of the inputted TPSA, 
with maximum order specified by `mo`. If `MAD_TPSA_SAME` is passed for `mo`, the `mo` 
currently in `t` is used for the created TPSA. Ok with `t=(tpsa_t*)ctpsa`

### Input
- `t`   -- TPSA
- `mo`  -- Maximum order of new TPSA

### Output
- `ret` -- New blank TPSA with maximum order `mo`
"""
function mad_tpsa_new(t::Ptr{TPS}, mo::Cuchar)::Ptr{TPS}
  ret = @ccall MAD_TPSA.mad_tpsa_new(t::Ptr{TPS}, mo::Cuchar)::Ptr{TPS}
  return ret
end


"""
    mad_tpsa_del!(t::Ptr{TPS})

Calls the destructor for the TPSA.

### Input
- `t` -- TPSA to destruct
"""
function mad_tpsa_del!(t::Ptr{TPS})
  @ccall MAD_TPSA.mad_tpsa_del(t::Ptr{TPS})::Cvoid
end


"""
    mad_tpsa_desc(t::Ptr{TPS})::Ptr{Desc}

Gets the descriptor for the TPSA.

### Input
- `t`   -- TPSA

### Output
- `ret` -- Descriptor for the TPS
"""
function mad_tpsa_desc(t::Ptr{TPS})::Ptr{Desc}
  ret = @ccall MAD_TPSA.mad_tpsa_desc(t::Ptr{TPS})::Ptr{Desc}
  return ret
end


"""
    mad_tpsa_uid!(t::Ptr{TPS}, uid_::Cint)::Cint

Sets the TPSA uid if `uid_ != 0`, and returns the current (previous if set) TPSA `uid`. 

### Input
- `t`    -- TPSA
- `uid_` -- `uid` to set in the TPSA if `uid_ != 0`

### Output
- `ret`  -- Current (previous if set) TPSA uid
"""
function mad_tpsa_uid!(t::Ptr{TPS}, uid_::Cint)::Cint
  ret = @ccall MAD_TPSA.mad_tpsa_uid(t::Ptr{TPS}, uid_::Cint)::Cint
  return ret
end


"""
    mad_tpsa_len(t::Ptr{TPS}, hi_::Bool)::Cint

Gets the length of the TPSA itself (e.g. the descriptor may be order 10 but TPSA may only be order 2)

### Input
- `t`   -- TPSA
- `hi_` -- If `true`, returns the length up to the `hi` order in the TPSA, else up to `mo`. Default is false
### Output
- `ret` -- Length of TPS
"""
function mad_tpsa_len(t::Ptr{TPS}, hi_::Bool)::Cint
  ret = @ccall MAD_TPSA.mad_tpsa_len(t::Ptr{TPS}, hi_::Bool)::Cint
  return ret
end


"""
    mad_tpsa_mo!(t::Ptr{TPS}, mo::Cuchar)::Cuchar

Sets the maximum order `mo` of the TPSA `t`, and returns the original `mo`.
`mo_` should be less than or equal to the allocated order `ao`.

### Input
- `t`   -- TPSA
- `mo_` -- Maximum order to set the TPSA

### Output
- `ret` -- Original `mo` of the TPSA
"""
function mad_tpsa_mo!(t::Ptr{TPS}, mo::Cuchar)::Cuchar
  ret = @ccall MAD_TPSA.mad_tpsa_mo(t::Ptr{TPS}, mo::Cuchar)::Cuchar
  return ret
end


"""
    mad_tpsa_nam(t::Ptr{TPS}, nam_)::Cstring

Get the name of the TPSA, and will optionally set if `nam_ != null`

### Input
- `t`    -- TPSA
- `nam_` -- Name to set the TPSA

### Output
- `ret`  -- Name of TPS (null terminated in C)
"""
function mad_tpsa_nam(t::Ptr{TPS}, nam_)::Cstring
  ret = @ccall MAD_TPSA.mad_tpsa_nam(t::Ptr{TPS}, nam_::Cstring)::Cstring
  return ret
end


"""
    mad_tpsa_ord(t::Ptr{TPS}, hi_::Bool)::Cuchar

Gets the TPSA maximum order, or `hi` if `hi_` is true.

### Input
- `t`   -- TPSA
- `hi_` -- Set `true` if `hi` is returned, else `mo` is returned

### Output
- `ret` -- Order of TPSA
"""
function mad_tpsa_ord(t::Ptr{TPS}, hi_::Bool)::Cuchar
  ret = @ccall MAD_TPSA.mad_tpsa_ord(t::Ptr{TPS}, hi_::Bool)::Cuchar
  return ret
end

"""
    mad_tpsa_ordv(t::Ptr{TPS}, ts::Ptr{TPS}...)::Cuchar

Returns maximum order of all TPSAs provided.

### Input
- `t`  -- TPSA
- `ts` -- Variable number of TPSAs passed as parameters

### Output
- `mo` -- Maximum order of all TPSAs provided
"""
function mad_tpsa_ordv(t::Ptr{TPS}, ts::Ptr{TPS}...)::Cuchar
  #mo = @ccall MAD_TPSA.mad_tpsa_ordv(t::Ptr{TPS}, ts::Ptr{TPS}..., 0::Cint)::Cuchar # null pointer after args for safe use
  mo = ccall((:mad_tpsa_ordv, MAD_TPSA), Cuchar, (Ptr{TPS}, Ptr{TPS}...), (t, ts...))
  return mo
end


"""
    mad_tpsa_copy!(t::Ptr{TPS}, r::Ptr{TPS})

Makes a copy of the TPSA `t` to `r`.

### Input
- `t` -- Source TPSA

### Output
- `r` -- Destination TPSA
"""
function mad_tpsa_copy!(t::Ptr{TPS}, r::Ptr{TPS})
  @ccall MAD_TPSA.mad_tpsa_copy(t::Ptr{TPS}, r::Ptr{TPS})::Cvoid
end


"""
    mad_tpsa_sclord!(t::Ptr{TPS}, r::Ptr{TPS}, inv::Bool, prm::Bool)

Scales all coefficients by order. If `inv == 0`, scales coefficients by order (derivation), else 
scales coefficients by 1/order (integration).

### Input
- `t`   -- Source TPSA
- `inv` -- Put order up, divide, scale by `inv` of value of order
- `prm` -- Parameters flag. If set to 0x0, the scaling excludes the order of the parameters in the monomials. Else, scaling is with total order of monomial

### Output
- `r`   -- Destination TPSA
"""
function mad_tpsa_sclord!(t::Ptr{TPS}, r::Ptr{TPS}, inv::Bool, prm::Bool)
  @ccall MAD_TPSA.mad_tpsa_sclord(t::Ptr{TPS}, r::Ptr{TPS}, inv::Bool, prm::Bool)::Cvoid
end


"""
    mad_tpsa_getord!(t::Ptr{TPS}, r::Ptr{TPS}, ord::Cuchar)

Extract one homogeneous polynomial of the given order

### Input
- `t`  -- Source TPSA
- `ord` -- Order to retrieve

### Output
- `r`   -- Destination TPSA
"""
function mad_tpsa_getord!(t::Ptr{TPS}, r::Ptr{TPS}, ord::Cuchar)
  @ccall MAD_TPSA.mad_tpsa_getord(t::Ptr{TPS}, r::Ptr{TPS}, ord::Cuchar)::Cvoid
end


"""
    mad_tpsa_cutord!(t::Ptr{TPS}, r::Ptr{TPS}, ord::Cint)

Cuts the TPSA off at the given order and above, or if `ord` is negative, will cut orders below 
`abs(ord)` (e.g. if ord = -3, then orders 0-3 are cut off).

### Input
- `t`   -- Source TPSA
- `ord` -- Cut order: `0..-ord` or `ord..mo`

### Output
- `r`   -- Destination TPSA
"""
function mad_tpsa_cutord!(t::Ptr{TPS}, r::Ptr{TPS}, ord::Cint)
  @ccall MAD_TPSA.mad_tpsa_cutord(t::Ptr{TPS}, r::Ptr{TPS}, ord::Cint)::Cvoid
end

"""
    mad_tpsa_clrord!(t::Ptr{TPS}, ord::Cuchar)

Clears all monomial coefficients of the TPSA at order `ord`

### Input
- `t` -- TPSA
- `ord` -- Order to clear monomial coefficients
"""
function mad_tpsa_clrord!(t::Ptr{TPS}, ord::Cuchar)
  @ccall MAD_TPSA.mad_tpsa_clrord(t::Ptr{TPS}, ord::Cuchar)::Cvoid
end

"""
    mad_tpsa_maxord!(t::Ptr{TPS}, n::Cint, idx_::Vector{Cint})::Cint

Returns the index to the monomial with maximum abs(coefficient) in the TPSA for all orders 0 to `n`. If `idx_` 
is provided, it is filled with the indices for the maximum abs(coefficient) monomial for each order up to `n`. 

### Input
- `t`    -- TPSA
- `n`    -- Highest order to include in finding the maximum abs(coefficient) in the TPSA, length of `idx_` if provided

### Output
- `idx_` -- (Optional) If provided, is filled with indices to the monomial for each order up to `n` with maximum abs(coefficient)
- `mi`   -- Index to the monomial in the TPSA with maximum abs(coefficient)
"""
function mad_tpsa_maxord!(t::Ptr{TPS}, n::Cint, idx_::Vector{Cint})::Cint
  mi = @ccall MAD_TPSA.mad_tpsa_maxord(t::Ptr{TPS}, n::Cint, idx_::Ptr{Cint})::Cint
  return mi
end

"""
    mad_tpsa_convert!(t::Ptr{TPS}, r::Ptr{TPS}, n::Cint, t2r_::Vector{Cint}, pb::Cint)

General function to convert TPSAs to different orders and reshuffle canonical coordinates. The destination TPSA will 
be of order `n`, and optionally have the variable reshuffling defined by `t2r_` and poisson bracket sign. e.g. if 
`t2r_ = {1,2,3,4,6,5}` and `pb = -1`, canonical coordinates 6 and 5 are swapped and the new 5th canonical coordinate 
will be negated. Useful for comparing with different differential algebra packages.

### Input
- `t`    -- Source TPSA
- `n`    -- Length of vector
- `t2r_` -- (Optional) Vector of index lookup
- `pb`   -- Poisson bracket, 0, 1:fwd, -1:bwd

### Output
- `r`    -- Destination TPSA with specified order and canonical coordinate reshuffling.
"""
function mad_tpsa_convert!(t::Ptr{TPS}, r::Ptr{TPS}, n::Cint, t2r_::Vector{Cint}, pb::Cint)
  @ccall MAD_TPSA.mad_tpsa_convert(t::Ptr{TPS}, r::Ptr{TPS}, n::Cint, t2r_::Ptr{Cint}, pb::Cint)::Cvoid
end


"""
    mad_tpsa_setvar!(t::Ptr{TPS}, v::Cdouble, iv::Cint, scl_::Cdouble)

Sets the 0th and 1st order values for the specified variable, and sets the rest of the variables/parameters to 0

### Input
- `t`    -- TPSA
- `v`    -- 0th order value (coefficient)
- `iv`   -- Variable index
- `scl_` -- 1st order variable value (typically will be 1)
"""
function mad_tpsa_setvar!(t::Ptr{TPS}, v::Cdouble, iv::Cint, scl_::Cdouble)
  @ccall MAD_TPSA.mad_tpsa_setvar(t::Ptr{TPS}, v::Cdouble, iv::Cint, scl_::Cdouble)::Cvoid
end

"""
    mad_tpsa_setprm!(t::Ptr{TPS}, v::Cdouble, ip::Cint)

Sets the 0th and 1st order values for the specified parameter, and sets the rest of the variables/parameters to 0. 
The 1st order value `scl_` of a parameter is always 1.

### Input
- `t`    -- TPSA
- `v`    -- 0th order value (coefficient)
- `ip`   -- Parameter index (e.g. iv = 1 is nn-nv+1)
"""
function mad_tpsa_setprm!(t::Ptr{TPS}, v::Cdouble, ip::Cint)
  @ccall MAD_TPSA.mad_tpsa_setprm(t::Ptr{TPS}, v::Cdouble, ip::Cint)::Cvoid
end

"""
    mad_tpsa_setval!(t::Ptr{TPS}, v::Cdouble)

Sets the scalar part of the TPSA to `v` and all other values to 0 (sets the TPSA order to 0).

### Input
- `t` -- TPSA to set to scalar
- `v` -- Scalar value to set TPSA
"""
function mad_tpsa_setval!(t::Ptr{TPS}, v::Cdouble)
  @ccall MAD_TPSA.mad_tpsa_setval(t::Ptr{TPS}, v::Cdouble)::Cvoid
end

"""
    mad_tpsa_update!(t::Ptr{TPS})

    ???
"""
function mad_tpsa_update!(t::Ptr{TPS})
  @ccall MAD_TPSA.mad_tpsa_update(t::Ptr{TPS})::Cvoid
end


"""
    mad_tpsa_clear!(t::Ptr{TPS})

Clears the TPSA (reset to 0)

### Input
- `t` -- TPSA
"""
function mad_tpsa_clear!(t::Ptr{TPS})
  @ccall MAD_TPSA.mad_tpsa_clear(t::Ptr{TPS})::Cvoid
end


"""
    mad_tpsa_isnul(t::Ptr{TPS})::Bool

Checks if TPSA is 0 or not

### Input
- `t`    -- TPSA to check

### Output
- `ret`  -- True or false
"""
function mad_tpsa_isnul(t::Ptr{TPS})::Bool
  ret = @ccall MAD_TPSA.mad_tpsa_isnul(t::Ptr{TPS})::Bool
  return ret
end


"""
    mad_tpsa_mono!(t::Ptr{TPS}, i::Cint, n::Cint, m_::Vector{Cuchar}, p_::Vector{Cuchar})::Cuchar

Returns the order of the monomial at index `i` in the TPSA and optionally the monomial at that index is returned in `m_` 
and the order of parameters in the monomial in `p_`

### Input
- `t`   -- TPSA
- `i`   -- Index valid in TPSA
- `n`   -- Length of monomial

### Output
- `m_`  -- (Optional) Monomial at index `i` in TPSA
- `p_`  -- (Optional) Order of parameters in monomial
- `ret` -- Order of monomial in TPSA `a`t index `i`
"""
function mad_tpsa_mono!(t::Ptr{TPS}, i::Cint, n::Cint, m_::Vector{Cuchar}, p_::Vector{Cuchar})::Cuchar
  ret = @ccall MAD_TPSA.mad_tpsa_mono(t::Ptr{TPS}, i::Cint, n::Cint, m_::Ptr{Cuchar}, p_::Ptr{Cuchar})::Cuchar
  return ret
end


"""
    mad_tpsa_idxs(t::Ptr{TPS}, n::Cint, s::Cstring)::Cint

Returns index of monomial in the TPSA given the monomial as string. This generally should not be used, as there 
are no assumptions about which monomial is attached to which index.

### Input
- `t`   -- TPSA
- `n`   -- Length of monomial
- `s`   -- Monomial as string

### Output
- `ret` -- Index of monomial in TPSA
"""
function mad_tpsa_idxs(t::Ptr{TPS}, n::Cint, s::Cstring)::Cint
  ret = @ccall MAD_TPSA.mad_tpsa_idxs(t::Ptr{TPS}, n::Cint, s::Cstring)::Cint
  return ret
end



"""
    mad_tpsa_idxm(t::Ptr{TPS}, n::Cint, m::Vector{Cuchar})::Cint

Returns index of monomial in the TPSA given the monomial as a byte array

### Input
- `t`   -- TPSA
- `n`   -- Length of monomial
- `s`   -- Monomial as byte array

### Output
- `ret` -- Index of monomial in TPSA
"""
function mad_tpsa_idxm(t::Ptr{TPS}, n::Cint, m::Vector{Cuchar})::Cint
  ret = @ccall MAD_TPSA.mad_tpsa_idxm(t::Ptr{TPS}, n::Cint, m::Ptr{Cuchar})::Cint
  return ret
end


"""
    mad_tpsa_idxsm(t::Ptr{TPS}, n::Cint, m::Vector{Cint})::Cint

Returns index of monomial in the TPSA given the monomial as a sparse monomial. This generally should not be used, as there 
are no assumptions about which monomial is attached to which index.

### Input
- `t`   -- TPSA
- `n`   -- Length of monomial
- `s`   -- Monomial as sparse monomial

### Output
- `ret` -- Index of monomial in TPSA
"""
function mad_tpsa_idxsm(t::Ptr{TPS}, n::Cint, m::Vector{Cint})::Cint
  ret = @ccall MAD_TPSA.mad_tpsa_idxsm(t::Ptr{TPS}, n::Cint, m::Ptr{Cint})::Cint
  return ret
end


"""
    mad_tpsa_cycle!(t::Ptr{TPS}, i::Cint, n::Cint, m_, v_)::Cint

Used for scanning through each nonzero monomial in the TPSA. Given a starting index (-1 if starting at 0), will 
optionally fill monomial `m_` with the monomial at index `i` and the value at `v_` with the monomials coefficient, and 
return the next NONZERO monomial index in the TPSA. This is useful for building an iterator through the TPSA.

### Input
- `t`  -- TPSA to scan
- `i`  -- Index to start from (-1 to start at 0)
- `n`  -- Length of monomial
- `m_` -- (Optional) Monomial to be filled if provided
- `v_` -- (Optional) Pointer to value of coefficient

### Output
- `i`  -- Index of next nonzero monomial in the TPSA, or -1 if reached the end
"""
function mad_tpsa_cycle!(t::Ptr{TPS}, i::Cint, n::Cint, m_, v_)::Cint
  i = @ccall MAD_TPSA.mad_tpsa_cycle(t::Ptr{TPS}, i::Cint, n::Cint, m_::Ptr{Cuchar}, v_::Ptr{Cdouble})::Cint
  return i
end


"""
    mad_tpsa_geti(t::Ptr{TPS}, i::Cint)::Cdouble

Gets the coefficient of the monomial at index `i`. Generally should use `mad_tpsa_cycle` instead of this.

### Input
- `t`   -- TPSA
- `i`   -- Monomial index

### Output
- `ret` -- Coefficient of monomial at index `i`
"""
function mad_tpsa_geti(t::Ptr{TPS}, i::Cint)::Cdouble
  ret = @ccall MAD_TPSA.mad_tpsa_geti(t::Ptr{TPS}, i::Cint)::Cdouble
  return ret
end


"""
    mad_tpsa_gets(t::Ptr{TPS}, n::Cint, s::Cstring)::Cdouble

Gets the coefficient of the monomial `s` defined as a string. Generally should use `mad_tpsa_cycle` instead of this.

### Input
- `t`   -- TPSA
- `n`   -- Length of monomial
- `s`   -- Monomial as string

### Output
- `ret` -- Coefficient of monomial `s` in TPSA
"""
function mad_tpsa_gets(t::Ptr{TPS}, n::Cint, s::Cstring)::Cdouble
  ret = @ccall MAD_TPSA.mad_tpsa_gets(t::Ptr{TPS}, n::Cint, s::Cstring)::Cdouble
  return ret
end


"""
    mad_tpsa_getm(t::Ptr{TPS}, n::Cint, m::Vector{Cuchar})::Cdouble

Gets the coefficient of the monomial `m` defined as a byte array. Generally should use `mad_tpsa_cycle` instead of this.

### Input
- `t`   -- TPSA
- `n`   -- Length of monomial
- `m`   -- Monomial as byte array

### Output
- `ret` -- Coefficient of monomial `m` in TPSA
"""
function mad_tpsa_getm(t::Ptr{TPS}, n::Cint, m::Vector{Cuchar})::Cdouble
  ret = @ccall MAD_TPSA.mad_tpsa_getm(t::Ptr{TPS}, n::Cint, m::Ptr{Cuchar})::Cdouble
  return ret
end


"""
    mad_tpsa_getsm(t::Ptr{TPS}, n::Cint, m::Vector{Cint})::Cdouble

Gets the coefficient of the monomial `m` defined as a sparse monomial. Generally should use `mad_tpsa_cycle` instead of this.

### Input
- `t`   -- TPSA
- `n`   -- Length of monomial
- `m`   -- Monomial as sparse monomial

### Output
- `ret` -- Coefficient of monomial `m` in TPSA
"""
function mad_tpsa_getsm(t::Ptr{TPS}, n::Cint, m::Vector{Cint})::Cdouble
  ret = @ccall MAD_TPSA.mad_tpsa_getsm(t::Ptr{TPS}, n::Cint, m::Ptr{Cint})::Cdouble
  return ret
end



"""
    mad_tpsa_seti!(t::Ptr{TPS}, i::Cint, a::Cdouble, b::Cdouble)

Sets the coefficient of monomial at index `i` to `coef[i] = a*coef[i] + b`. Does not modify other values in TPSA.

### Input
- `t` -- TPSA
- `i` -- Index of monomial
- `a` -- Scaling of current coefficient
- `b` -- Constant added to current coefficient
"""
function mad_tpsa_seti!(t, i, a, b)
  @ccall MAD_TPSA.mad_tpsa_seti(t::Ptr{TPS}, i::Cint, a::Cdouble, b::Cdouble)::Cvoid
end


"""
    mad_tpsa_sets!(t::Ptr{TPS}, n::Cint, s::Cstring, a::Cdouble, b::Cdouble)

Sets the coefficient of monomial defined by string `s` to `coef = a*coef + b`. Does not modify other values in TPSA.

### Input
- `t` -- TPSA
- `n` -- Length of monomial
- `s` -- Monomial as string
- `a` -- Scaling of current coefficient
- `b` -- Constant added to current coefficient
"""
function mad_tpsa_sets!(t::Ptr{TPS}, n::Cint, s::Cstring, a::Cdouble, b::Cdouble)
  @ccall MAD_TPSA.mad_tpsa_sets(t::Ptr{TPS}, n::Cint, s::Cstring, a::Cdouble, b::Cdouble)::Cvoid
end


"""
    mad_tpsa_setm!(t::Ptr{TPS}, n::Cint, m::Vector{Cuchar}, a::Cdouble, b::Cdouble)

Sets the coefficient of monomial defined by byte array `m` to `coef = a*coef + b`. Does not modify other values in TPSA.

### Input
- `t` -- TPSA
- `n` -- Length of monomial
- `m` -- Monomial as byte array
- `a` -- Scaling of current coefficient
- `b` -- Constant added to current coefficient
"""
function mad_tpsa_setm!(t::Ptr{TPS}, n::Cint, m::Vector{Cuchar}, a::Cdouble, b::Cdouble)
  @ccall MAD_TPSA.mad_tpsa_setm(t::Ptr{TPS}, n::Cint, m::Ptr{Cuchar}, a::Cdouble, b::Cdouble)::Cvoid
end


"""
    mad_tpsa_setsm!(t::Ptr{TPS}, n::Cint, m::Vector{Cint}, a::Cdouble, b::Cdouble)

Sets the coefficient of monomial defined by sparse monomial `m` to `coef = a*coef + b`. Does not modify other values in TPSA.

### Input
- `t` -- TPSA
- `n` -- Length of monomial
- `m` -- Monomial as sparse monomial
- `a` -- Scaling of current coefficient
- `b` -- Constant added to current coefficient
"""
function mad_tpsa_setsm!(t::Ptr{TPS}, n::Cint, m::Vector{Cint}, a::Cdouble, b::Cdouble)
  @ccall MAD_TPSA.mad_tpsa_setsm(t::Ptr{TPS}, n::Cint, m::Ptr{Cint}, a::Cdouble, b::Cdouble)::Cvoid
end


"""
    mad_tpsa_cpyi!(t::Ptr{TPS}, r::Ptr{TPS}, i::Cint)

Copies the monomial coefficient at index `i` in `t` into the 
same monomial coefficient in `r`

### Input
- `t` -- Source TPSA
- `r` -- Destination TPSA 
- `i` -- Index of monomial
"""
function mad_tpsa_cpyi!(t::Ptr{TPS}, r::Ptr{TPS}, i::Cint)
  @ccall MAD_TPSA.mad_tpsa_cpyi(t::Ptr{TPS}, r::Ptr{TPS}, i::Cint)::Cvoid
end

"""
    mad_tpsa_cpys!(t::Ptr{TPS}, r::Ptr{TPS}, n::Cint, s::Cstring)

Copies the monomial coefficient at the monomial-as-string-of-order
`s` in `t` into the same monomial coefficient in `r`

### Input
- `t` -- Source TPSA
- `r` -- Destination TPSA 
- `n` -- Length of string
- `s` -- Monomial as string
"""
function mad_tpsa_cpys!(t::Ptr{TPS}, r::Ptr{TPS}, n::Cint, s::Cstring)
  @ccall MAD_TPSA.mad_tpsa_cpys(t::Ptr{TPS}, r::Ptr{TPS}, n::Cint, s::Cstring)::Cvoid
end

"""
    mad_tpsa_cpym!(t::Ptr{TPS}, r::Ptr{TPS}, n::Cint, m::Vector{Cuchar})

Copies the monomial coefficient at the monomial-as-vector-of-orders
`m` in `t` into the same monomial coefficient in `r`

### Input
- `t` -- Source TPSA
- `r` -- Destination TPSA 
- `n` -- Length of monomial `m`
- `m` -- Monomial as vector of orders
"""
function mad_tpsa_cpym!(t::Ptr{TPS}, r::Ptr{TPS}, n::Cint, m::Vector{Cuchar})
  @ccall MAD_TPSA.mad_tpsa_cpym(t::Ptr{TPS}, r::Ptr{TPS}, n::Cint, m::Ptr{Cuchar})::Cvoid
end

"""
    mad_tpsa_cpysm!(t::Ptr{TPS}, r::Ptr{TPS}, n::Cint, m::Vector{Cint})

    ???
"""
function mad_tpsa_cpysm!(t::Ptr{TPS}, r::Ptr{TPS}, n::Cint, m::Vector{Cint})
  @ccall MAD_TPSA.mad_tpsa_cpysm(t::Ptr{TPS}, r::Ptr{TPS}, n::Cint, m::Ptr{Cint})::Cvoid
end


"""
    mad_tpsa_getv!(t::Ptr{TPS}, i::Cint, n::Cint, v)


Vectorized getter of the coefficients for monomials with indices `i..i+n`. Useful for extracting the 1st order parts of 
a TPSA to construct a matrix (`i = 1`, `n = nv+np = nn`). 

### Input
- `t` -- TPSA
- `i` -- Starting index of monomials to get coefficients
- `n` -- Number of monomials to get coefficients of starting at `i`

### Output
- `v` -- Array of coefficients for monomials `i..i+n`
"""
function mad_tpsa_getv!(t::Ptr{TPS}, i::Cint, n::Cint, v)
  @ccall MAD_TPSA.mad_tpsa_getv(t::Ptr{TPS}, i::Cint, n::Cint, v::Ptr{Cdouble})::Cvoid
end


"""
    mad_tpsa_setv!(t::Ptr{TPS}, i::Cint, n::Cint, v::Vector{Cdouble})

Vectorized setter of the coefficients for monomials with indices `i..i+n`. Useful for putting a matrix into a map.

### Input
- `t` -- TPSA
- `i` -- Starting index of monomials to set coefficients
- `n` -- Number of monomials to set coefficients of starting at `i`
- `v` -- Array of coefficients for monomials `i..i+n`
"""
function mad_tpsa_setv!(t::Ptr{TPS}, i::Cint, n::Cint, v::Vector{Cdouble})
  @ccall MAD_TPSA.mad_tpsa_setv(t::Ptr{TPS}, i::Cint, n::Cint, v::Ptr{Cdouble})::Cvoid
end


"""
    mad_tpsa_equ(a::Ptr{TPS}, b::Ptr{TPS}, tol_::Cdouble)::Bool

Checks if the TPSAs `a` and `b` are equal within the specified tolerance `tol_`. If `tol_` is not specified, `DBL_GTPSA.show_epsILON` is used.

### Input
- `a`    -- TPSA `a`
- `b`    -- TPSA `b`
- `tol_` -- (Optional) Difference below which the TPSAs are considered equal

### Output
- `ret`   - True if `a == b` within `tol_`
"""
function mad_tpsa_equ(a::Ptr{TPS}, b::Ptr{TPS}, tol_::Cdouble)::Bool
  ret = @ccall MAD_TPSA.mad_tpsa_equ(a::Ptr{TPS}, b::Ptr{TPS}, tol_::Cdouble)::Bool
  return ret
end


"""
    mad_tpsa_dif!(a::Ptr{TPS}, b::Ptr{TPS}, c::Ptr{TPS})

For each homogeneous polynomial in TPSAs `a` and `b`, calculates either the relative error or absolute error for each order.
If the maximum coefficient for a given order in `a` is > 1, the relative error is computed for that order. Else, the absolute 
error is computed. This is very useful for comparing maps between codes or doing unit tests. In Julia, essentially:

`c_i = (a_i.-b_i)/maximum([abs.(a_i)...,1])` where `a_i` and `b_i` are vectors of the monomials for an order `i`

### Input
- `a` -- Source TPSA `a`
- `b` -- Source TPSA `b`

### Output
- `c` -- Destination TPSA `c` 
"""
function mad_tpsa_dif!(a::Ptr{TPS}, b::Ptr{TPS}, c::Ptr{TPS})
  @ccall MAD_TPSA.mad_tpsa_dif(a::Ptr{TPS}, b::Ptr{TPS}, c::Ptr{TPS})::Cvoid
end


"""
    mad_tpsa_add!(a::Ptr{TPS}, b::Ptr{TPS}, c::Ptr{TPS})

Sets the destination TPSA `c = a + b`

### Input
- `a` -- Source TPSA `a`
- `b` -- Source TPSA `b`

### Output
- `c` -- Destination TPSA `c = a + b`
"""
function mad_tpsa_add!(a::Ptr{TPS}, b::Ptr{TPS}, c::Ptr{TPS})
  @ccall MAD_TPSA.mad_tpsa_add(a::Ptr{TPS}, b::Ptr{TPS}, c::Ptr{TPS})::Cvoid
end


"""
    mad_tpsa_sub!(a::Ptr{TPS}, b::Ptr{TPS}, c::Ptr{TPS})

Sets the destination TPSA `c = a - b`

### Input
- `a` -- Source TPSA `a`
- `b` -- Source TPSA `b`

### Output
- `c` -- Destination TPSA `c = a - b`
"""
function mad_tpsa_sub!(a::Ptr{TPS}, b::Ptr{TPS}, c::Ptr{TPS})
  @ccall MAD_TPSA.mad_tpsa_sub(a::Ptr{TPS}, b::Ptr{TPS}, c::Ptr{TPS})::Cvoid
end


"""
    mad_tpsa_mul!(a::Ptr{TPS}, b::Ptr{TPS}, c::Ptr{TPS})

Sets the destination TPSA `c = a * b`

### Input
- `a` -- Source TPSA `a`
- `b` -- Source TPSA `b`

### Output
- `c` -- Destination TPSA `c = a * b`
"""
function mad_tpsa_mul!(a::Ptr{TPS}, b::Ptr{TPS}, c::Ptr{TPS})
  @ccall MAD_TPSA.mad_tpsa_mul(a::Ptr{TPS}, b::Ptr{TPS}, c::Ptr{TPS})::Cvoid
end


"""
    mad_tpsa_div!(a::Ptr{TPS}, b::Ptr{TPS}, c::Ptr{TPS})

Sets the destination TPSA `c = a / b`

### Input
- `a` -- Source TPSA `a`
- `b` -- Source TPSA `b`

### Output
- `c` -- Destination TPSA `c = a / b`
"""
function mad_tpsa_div!(a::Ptr{TPS}, b::Ptr{TPS}, c::Ptr{TPS})
  @ccall MAD_TPSA.mad_tpsa_div(a::Ptr{TPS}, b::Ptr{TPS}, c::Ptr{TPS})::Cvoid
end


"""
    mad_tpsa_pow!(a::Ptr{TPS}, b::Ptr{TPS}, c::Ptr{TPS})

Sets the destination TPSA `c = a ^ b`

### Input
- `a` -- Source TPSA `a`
- `b` -- Source TPSA `b`

### Output
- `c` -- Destination TPSA `c = a ^ b`
"""
function mad_tpsa_pow!(a::Ptr{TPS}, b::Ptr{TPS}, c::Ptr{TPS})
  @ccall MAD_TPSA.mad_tpsa_pow(a::Ptr{TPS}, b::Ptr{TPS}, c::Ptr{TPS})::Cvoid
end


"""
    mad_tpsa_powi!(a::Ptr{TPS}, n::Cint, c::Ptr{TPS})

Sets the destination TPSA `c = a ^ n` where `n` is an integer.

### Input
- `a` -- Source TPSA `a`
- `n` -- Integer power

### Output
- `c` -- Destination TPSA `c = a ^ n`
"""
function mad_tpsa_powi!(a::Ptr{TPS}, n::Cint, c::Ptr{TPS})
  @ccall MAD_TPSA.mad_tpsa_powi(a::Ptr{TPS}, n::Cint, c::Ptr{TPS})::Cvoid
end


"""
    mad_tpsa_pown!(a::Ptr{TPS}, v::Cdouble, c::Ptr{TPS})

Sets the destination TPSA `c = a ^ v` where `v` is of double precision.

### Input
- `a` -- Source TPSA `a`
- `v` -- "double" precision power

### Output
- `c` -- Destination TPSA `c = a ^ v`
"""
function mad_tpsa_pown!(a::Ptr{TPS}, v::Cdouble, c::Ptr{TPS})
  @ccall MAD_TPSA.mad_tpsa_pown(a::Ptr{TPS}, v::Cdouble, c::Ptr{TPS})::Cvoid
end


"""
    mad_tpsa_nrm(a::Ptr{TPS})::Cdouble

Calculates the 1-norm of TPSA `a` (sum of `abs` of all coefficients)

### Input
- `a`   -- TPSA

### Output
- `nrm` -- 1-Norm of TPSA
"""
function mad_tpsa_nrm(a::Ptr{TPS})::Cdouble
  nrm = @ccall MAD_TPSA.mad_tpsa_nrm(a::Ptr{TPS})::Cdouble
  return nrm
end


"""
    mad_tpsa_abs!(a::Ptr{TPS}, c::Ptr{TPS})

Sets TPSA `c` to the absolute value of TPSA `a`. Specifically, the 
result contains a TPSA with the `abs` of all coefficients.

### Input
- `a` -- Source TPSA `a`

### Output
- `c` -- Destination TPSA `c = |a|`
"""
function mad_tpsa_abs!(a::Ptr{TPS}, c::Ptr{TPS})
  @ccall MAD_TPSA.mad_tpsa_abs(a::Ptr{TPS}, c::Ptr{TPS})::Cvoid
end


"""
    mad_tpsa_sqrt!(a::Ptr{TPS}, c::Ptr{TPS})

Sets TPSA `c` to the sqrt of TPSA `a`.

### Input
- `a` -- Source TPSA `a`

### Output
- `c` -- Destination TPSA `c = sqrt(a)`
"""
function mad_tpsa_sqrt!(a::Ptr{TPS}, c::Ptr{TPS})
  @ccall MAD_TPSA.mad_tpsa_sqrt(a::Ptr{TPS}, c::Ptr{TPS})::Cvoid
end


"""
    mad_tpsa_exp!(a::Ptr{TPS}, c::Ptr{TPS})

Sets TPSA `c` to the exponential of TPSA `a`.

### Input
- `a` -- Source TPSA `a`

### Output
- `c` -- Destination TPSA `c = exp(a)`
"""
function mad_tpsa_exp!(a::Ptr{TPS}, c::Ptr{TPS})
  @ccall MAD_TPSA.mad_tpsa_exp(a::Ptr{TPS}, c::Ptr{TPS})::Cvoid
end



"""
    mad_tpsa_log!(a::Ptr{TPS}, c::Ptr{TPS})

Sets TPSA `c` to the log of TPSA `a`.

### Input
- `a` -- Source TPSA `a`

### Output
- `c` -- Destination TPSA `c = log(a)`
"""
function mad_tpsa_log!(a::Ptr{TPS}, c::Ptr{TPS})
  @ccall MAD_TPSA.mad_tpsa_log(a::Ptr{TPS}, c::Ptr{TPS})::Cvoid
end


"""
    mad_tpsa_sincos!(a::Ptr{TPS}, s::Ptr{TPS}, c::Ptr{TPS})

Sets TPSA `s = sin(a)` and TPSA `c = cos(a)`

### Input
- `a` -- Source TPSA `a`

### Output
- `s` -- Destination TPSA `s = sin(a)`
- `c` -- Destination TPSA `c = cos(a)`
"""
function mad_tpsa_sincos!(a::Ptr{TPS}, s::Ptr{TPS}, c::Ptr{TPS})
  @ccall MAD_TPSA.mad_tpsa_sincos(a::Ptr{TPS}, s::Ptr{TPS}, c::Ptr{TPS})::Cvoid
end


"""
    mad_tpsa_sin!(a::Ptr{TPS}, c::Ptr{TPS})

Sets TPSA `c` to the `sin` of TPSA `a`.

### Input
- `a` -- Source TPSA `a`

### Output
- `c` -- Destination TPSA `c = sin(a)`
"""
function mad_tpsa_sin!(a::Ptr{TPS}, c::Ptr{TPS})
  @ccall MAD_TPSA.mad_tpsa_sin(a::Ptr{TPS}, c::Ptr{TPS})::Cvoid
end


"""
    mad_tpsa_cos!(a::Ptr{TPS}, c::Ptr{TPS})

Sets TPSA `c` to the `cos` of TPSA `a`.

### Input
- `a` -- Source TPSA `a`

### Output
- `c` -- Destination TPSA `c = cos(a)`
"""
function mad_tpsa_cos!(a::Ptr{TPS}, c::Ptr{TPS})
  @ccall MAD_TPSA.mad_tpsa_cos(a::Ptr{TPS}, c::Ptr{TPS})::Cvoid
end


"""
    mad_tpsa_tan!(a::Ptr{TPS}, c::Ptr{TPS})

Sets TPSA `c` to the `tan` of TPSA `a`.

### Input
- `a` -- Source TPSA `a`

### Output
- `c` -- Destination TPSA `c = tan(a)`
"""
function mad_tpsa_tan!(a::Ptr{TPS}, c::Ptr{TPS})
  @ccall MAD_TPSA.mad_tpsa_tan(a::Ptr{TPS}, c::Ptr{TPS})::Cvoid
end


"""
    mad_tpsa_cot!(a::Ptr{TPS}, c::Ptr{TPS})

Sets TPSA `c` to the `cot` of TPSA `a`.

### Input
- `a` -- Source TPSA `a`

### Output
- `c` -- Destination TPSA `c = cot(a)`
"""
function mad_tpsa_cot!(a::Ptr{TPS}, c::Ptr{TPS})
  @ccall MAD_TPSA.mad_tpsa_cot(a::Ptr{TPS}, c::Ptr{TPS})::Cvoid
end


"""
    mad_tpsa_sinc!(a::Ptr{TPS}, c::Ptr{TPS})

Sets TPSA `c` to the `sinc` of TPSA `a`.

### Input
- `a` -- Source TPSA `a`

### Output
- `c` -- Destination TPSA `c = sinc(a)`
"""
function mad_tpsa_sinc!(a::Ptr{TPS}, c::Ptr{TPS})
  @ccall MAD_TPSA.mad_tpsa_sinc(a::Ptr{TPS}, c::Ptr{TPS})::Cvoid
end


"""
    mad_tpsa_sincosh!(a::Ptr{TPS}, s::Ptr{TPS}, c::Ptr{TPS})

Sets TPSA `s = sinh(a)` and TPSA `c = cosh(a)`

### Input
- `a` -- Source TPSA `a`

### Output
- `s` -- Destination TPSA `s = sinh(a)`
- `c` -- Destination TPSA `c = cosh(a)`
"""
function mad_tpsa_sincosh!(a::Ptr{TPS}, s::Ptr{TPS}, c::Ptr{TPS})
  @ccall MAD_TPSA.mad_tpsa_sincosh(a::Ptr{TPS}, s::Ptr{TPS}, c::Ptr{TPS})::Cvoid
end


"""
    mad_tpsa_sinh!(a::Ptr{TPS}, c::Ptr{TPS})

  Sets TPSA `c` to the `sinh` of TPSA `a`.

### Input
- `a` -- Source TPSA `a`

### Output
- `c` -- Destination TPSA `c = sinh(a)`
"""
function mad_tpsa_sinh!(a::Ptr{TPS}, c::Ptr{TPS})
  @ccall MAD_TPSA.mad_tpsa_sinh(a::Ptr{TPS}, c::Ptr{TPS})::Cvoid
end


"""
    mad_tpsa_cosh!(a::Ptr{TPS}, c::Ptr{TPS})

Sets TPSA `c` to the `cosh` of TPSA `a`.

### Input
- `a` -- Source TPSA `a`

### Output
- `c` -- Destination TPSA `c = cosh(a)`
"""
function mad_tpsa_cosh!(a::Ptr{TPS}, c::Ptr{TPS})
  @ccall MAD_TPSA.mad_tpsa_cosh(a::Ptr{TPS}, c::Ptr{TPS})::Cvoid
end


"""
    mad_tpsa_tanh!(a::Ptr{TPS}, c::Ptr{TPS})

Sets TPSA `c` to the `tanh` of TPSA `a`.

### Input
- `a` -- Source TPSA `a`

### Output
- `c` -- Destination TPSA `c = tanh(a)`
"""
function mad_tpsa_tanh!(a::Ptr{TPS}, c::Ptr{TPS})
  @ccall MAD_TPSA.mad_tpsa_tanh(a::Ptr{TPS}, c::Ptr{TPS})::Cvoid
end


"""
    mad_tpsa_coth!(a::Ptr{TPS}, c::Ptr{TPS})

Sets TPSA `c` to the `coth` of TPSA `a`.

### Input
- `a` -- Source TPSA `a`

### Output
- `c` -- Destination TPSA `c = coth(a)`
"""
function mad_tpsa_coth!(a::Ptr{TPS}, c::Ptr{TPS})
  @ccall MAD_TPSA.mad_tpsa_coth(a::Ptr{TPS}, c::Ptr{TPS})::Cvoid
end


"""
    mad_tpsa_sinhc!(a::Ptr{TPS}, c::Ptr{TPS})

Sets TPSA `c` to the `sinhc` of TPSA `a`.

### Input
- `a` -- Source TPSA `a`

### Output
- `c` -- Destination TPSA `c = sinhc(a)`
"""
function mad_tpsa_sinhc!(a::Ptr{TPS}, c::Ptr{TPS})
  @ccall MAD_TPSA.mad_tpsa_sinhc(a::Ptr{TPS}, c::Ptr{TPS})::Cvoid
end


"""
    mad_tpsa_asin!(a::Ptr{TPS}, c::Ptr{TPS})

Sets TPSA `c` to the `asin` of TPSA `a`.

### Input
- `a` -- Source TPSA `a`

### Output
- `c` -- Destination TPSA `c = asin(a)`
"""
function mad_tpsa_asin!(a::Ptr{TPS}, c::Ptr{TPS})
  @ccall MAD_TPSA.mad_tpsa_asin(a::Ptr{TPS}, c::Ptr{TPS})::Cvoid
end


"""
    mad_tpsa_acos!(a::Ptr{TPS}, c::Ptr{TPS})

Sets TPSA `c` to the `acos` of TPSA `a`.

### Input
- `a` -- Source TPSA `a`

### Output
- `c` -- Destination TPSA `c = acos(a)`
"""
function mad_tpsa_acos!(a::Ptr{TPS}, c::Ptr{TPS})
  @ccall MAD_TPSA.mad_tpsa_acos(a::Ptr{TPS}, c::Ptr{TPS})::Cvoid
end


"""
    mad_tpsa_atan!(a::Ptr{TPS}, c::Ptr{TPS})

Sets TPSA `c` to the `atan` of TPSA `a`.

### Input
- `a` -- Source TPSA `a`

### Output
- `c` -- Destination TPSA `c = atan(a)`
"""
function mad_tpsa_atan!(a::Ptr{TPS}, c::Ptr{TPS})
  @ccall MAD_TPSA.mad_tpsa_atan(a::Ptr{TPS}, c::Ptr{TPS})::Cvoid
end


"""
    mad_tpsa_acot!(a::Ptr{TPS}, c::Ptr{TPS})

Sets TPSA `c` to the `acot` of TPSA `a`.

### Input
- `a` -- Source TPSA `a`

### Output
- `c` -- Destination TPSA `c = acot(a)`
"""
function mad_tpsa_acot!(a::Ptr{TPS}, c::Ptr{TPS})
  @ccall MAD_TPSA.mad_tpsa_acot(a::Ptr{TPS}, c::Ptr{TPS})::Cvoid
end

"""
    mad_tpsa_asinc!(a::Ptr{TPS}, c::Ptr{TPS})

Sets TPSA `c` to the `asinc(a) = asin(a)/a`

### Input
- `a` -- Source TPSA `a`

### Output
- `c` -- Destination TPSA `c = asinc(a) = asin(a)/a`
"""
function mad_tpsa_asinc!(a::Ptr{TPS}, c::Ptr{TPS})
  @ccall MAD_TPSA.mad_tpsa_asinc(a::Ptr{TPS}, c::Ptr{TPS})::Cvoid
end


"""
    mad_tpsa_asinh!(a::Ptr{TPS}, c::Ptr{TPS})

Sets TPSA `c` to the `asinh` of TPSA `a`.

### Input
- `a` -- Source TPSA `a`

### Output
- `c` -- Destination TPSA `c = asinh(a)'
"""
function mad_tpsa_asinh!(a::Ptr{TPS}, c::Ptr{TPS})
  @ccall MAD_TPSA.mad_tpsa_asinh(a::Ptr{TPS}, c::Ptr{TPS})::Cvoid
end


"""
    mad_tpsa_acosh!(a::Ptr{TPS}, c::Ptr{TPS})

Sets TPSA `c` to the `acosh` of TPSA `a`.

### Input
- `a` -- Source TPSA `a`

### Output
- `c` -- Destination TPSA `c = acosh(a)'
"""
function mad_tpsa_acosh!(a::Ptr{TPS}, c::Ptr{TPS})
  @ccall MAD_TPSA.mad_tpsa_acosh(a::Ptr{TPS}, c::Ptr{TPS})::Cvoid
end


"""
    mad_tpsa_atanh!(a::Ptr{TPS}, c::Ptr{TPS})

Sets TPSA `c` to the `atanh` of TPSA `a`.

### Input
- `a` -- Source TPSA `a`

### Output
- `c` -- Destination TPSA `c = atanh(a)'
"""
function mad_tpsa_atanh!(a::Ptr{TPS}, c::Ptr{TPS})
  @ccall MAD_TPSA.mad_tpsa_atanh(a::Ptr{TPS}, c::Ptr{TPS})::Cvoid
end


"""
    mad_tpsa_acoth!(a::Ptr{TPS}, c::Ptr{TPS})

Sets TPSA `c` to the acoth of TPSA `a`.

### Input
- `a` -- Source TPSA `a`

### Output
- `c` -- Destination TPSA `c = acoth(a)'
"""
function mad_tpsa_acoth!(a::Ptr{TPS}, c::Ptr{TPS})
  @ccall MAD_TPSA.mad_tpsa_acoth(a::Ptr{TPS}, c::Ptr{TPS})::Cvoid
end


"""
    mad_tpsa_asinhc!(a::Ptr{TPS}, c::Ptr{TPS})

Sets TPSA `c` to the `asinhc` of TPSA `a`.

### Input
- `a` -- Source TPSA `a`

### Output
- `c` -- Destination TPSA `c = asinhc(a)'
"""
function mad_tpsa_asinhc!(a::Ptr{TPS}, c::Ptr{TPS})
  @ccall MAD_TPSA.mad_tpsa_asinhc(a::Ptr{TPS}, c::Ptr{TPS})::Cvoid
end


"""
    mad_tpsa_erf!(a::Ptr{TPS}, c::Ptr{TPS})

Sets TPSA `c` to the `erf` of TPSA `a`.

### Input
- `a` -- Source TPSA `a`

### Output
- `c` -- Destination TPSA `c = erf(a)'
"""
function mad_tpsa_erf!(a::Ptr{TPS}, c::Ptr{TPS})
  @ccall MAD_TPSA.mad_tpsa_erf(a::Ptr{TPS}, c::Ptr{TPS})::Cvoid
end


"""
    mad_tpsa_erfc!(a::Ptr{TPS}, c::Ptr{TPS})

Sets TPSA `c` to the `erfc` of TPSA `a`.

### Input
- `a` -- Source TPSA `a`

### Output
- `c` -- Destination TPSA `c = erfc(a)'
"""
function mad_tpsa_erfc!(a::Ptr{TPS}, c::Ptr{TPS})
  @ccall MAD_TPSA.mad_tpsa_erfc(a::Ptr{TPS}, c::Ptr{TPS})::Cvoid
end


"""
    mad_tpsa_acc!(a::Ptr{TPS}, v::Cdouble, c::Ptr{TPS})

Adds `a*v` to TPSA `c`. Aliasing OK.

### Input
- `a` -- Source TPSA `a`
- `v` -- Scalar with double precision

### Output
- `c` -- Destination TPSA `c += v*a`
"""
function mad_tpsa_acc!(a::Ptr{TPS}, v::Cdouble, c::Ptr{TPS})
  @ccall MAD_TPSA.mad_tpsa_acc(a::Ptr{TPS}, v::Cdouble, c::Ptr{TPS})::Cvoid
end


"""
    mad_tpsa_scl!(a::Ptr{TPS}, v::Cdouble, c::Ptr{TPS})

Sets TPSA `c` to `v*a`. 

### Input
- `a` -- Source TPSA `a`
- `v` -- Scalar with double precision

### Output
- `c` -- Destination TPSA `c = v*a`
"""
function mad_tpsa_scl!(a::Ptr{TPS}, v::Cdouble, c::Ptr{TPS})
  @ccall MAD_TPSA.mad_tpsa_scl(a::Ptr{TPS}, v::Cdouble, c::Ptr{TPS})::Cvoid
end


"""
    mad_tpsa_inv!(a::Ptr{TPS},  v::Cdouble, c::Ptr{TPS})

Sets TPSA `c` to `v/a`. 

### Input
- `a` -- Source TPSA `a`
- `v` -- Scalar with double precision

### Output
- `c` -- Destination TPSA `c = v/a`
"""
function mad_tpsa_inv!(a::Ptr{TPS},  v::Cdouble, c::Ptr{TPS})
  @ccall MAD_TPSA.mad_tpsa_inv(a::Ptr{TPS},  v::Cdouble, c::Ptr{TPS})::Cvoid
end

"""
    mad_tpsa_invsqrt!(a::Ptr{TPS}, v::Cdouble, c::Ptr{TPS})

Sets TPSA `c` to `v/sqrt(a)`. 

### Input
- `a` -- Source TPSA `a`
- `v` -- Scalar with double precision

### Output
- `c` -- Destination TPSA `c = v/sqrt(a)`
"""
function mad_tpsa_invsqrt!(a::Ptr{TPS}, v::Cdouble, c::Ptr{TPS})
  @ccall MAD_TPSA.mad_tpsa_invsqrt(a::Ptr{TPS}, v::Cdouble, c::Ptr{TPS})::Cvoid
end


"""
    mad_tpsa_unit!(a::Ptr{TPS}, c::Ptr{TPS})

Interpreting TPSA as a vector, gets the "unit vector", e.g. `c = a/norm(a)`. 
May be useful for checking for convergence.

### Input
- `a` -- Source TPSA `a`

### Output
- `c` -- Destination TPSA `c`
"""
function  mad_tpsa_unit!(a::Ptr{TPS}, c::Ptr{TPS})
  @ccall MAD_TPSA.mad_tpsa_unit(a::Ptr{TPS}, c::Ptr{TPS})::Cvoid
end


"""
    mad_tpsa_atan2!(y::Ptr{TPS}, x::Ptr{TPS}, r::Ptr{TPS})

Sets TPSA `r` to `atan2(y,x)`

### Input
- `y` -- Source TPSA `y`
- `x` -- Source TPSA `x`

### Output
- `r` -- Destination TPSA r = atan2(y,x)
"""
function  mad_tpsa_atan2!(y::Ptr{TPS}, x::Ptr{TPS}, r::Ptr{TPS})
  @ccall MAD_TPSA.mad_tpsa_atan2(y::Ptr{TPS}, x::Ptr{TPS}, r::Ptr{TPS})::Cvoid
end

"""
    mad_tpsa_hypot!(x::Ptr{TPS}, y::Ptr{TPS}, r::Ptr{TPS})

Sets TPSA `r` to `sqrt(x^2+y^2)`. Used to oversimplify polymorphism in code but not optimized

### Input
- `x` -- Source TPSA `x`
- `y` -- Source TPSA `y`

### Output
- `r` -- Destination TPSA r = sqrt(x^2+y^2)
"""
function  mad_tpsa_hypot!(x::Ptr{TPS}, y::Ptr{TPS}, r::Ptr{TPS})
  @ccall MAD_TPSA.mad_tpsa_hypot(x::Ptr{TPS}, y::Ptr{TPS}, r::Ptr{TPS})::Cvoid
end

"""
    mad_tpsa_hypot3!(x::Ptr{TPS}, y::Ptr{TPS}, z::Ptr{TPS}, r::Ptr{TPS})

Sets TPSA `r` to `sqrt(x^2+y^2+z^2)`. Does NOT allow for r = x, y, z !!!

### Input
- `x` -- Source TPSA `x`
- `y` -- Source TPSA `y`
- `z` -- Source TPSA `z`

### Output
- `r` -- Destination TPSA `r = sqrt(x^2+y^2+z^2)`
"""
function  mad_tpsa_hypot3!(x::Ptr{TPS}, y::Ptr{TPS}, z::Ptr{TPS}, r::Ptr{TPS})
  @ccall MAD_TPSA.mad_tpsa_hypot3(x::Ptr{TPS}, y::Ptr{TPS}, z::Ptr{TPS}, r::Ptr{TPS})::Cvoid
end



"""
    mad_tpsa_integ!(a::Ptr{TPS}, c::Ptr{TPS}, iv::Cint)

Integrates TPSA with respect to the variable with index `iv`.

### Input
- `a`  -- Source TPSA to integrate
- `iv` -- Index of variable to integrate over (e.g. integrate over `x`, `iv = 1`). 

### Output
- `c`  -- Destination TPSA
"""
function mad_tpsa_integ!(a::Ptr{TPS}, c::Ptr{TPS}, iv::Cint)
  @ccall MAD_TPSA.mad_tpsa_integ(a::Ptr{TPS}, c::Ptr{TPS}, iv::Cint)::Cvoid
end


"""
    mad_tpsa_deriv!(a::Ptr{TPS}, c::Ptr{TPS}, iv::Cint)

Differentiates TPSA with respect to the variable with index `iv`.

### Input
- `a`  -- Source TPSA to differentiate
- `iv` -- Index of variable to take derivative wrt to (e.g. derivative wrt `x`, `iv = 1`). 

### Output
- `c`  -- Destination TPSA
"""
function mad_tpsa_deriv!(a::Ptr{TPS}, c::Ptr{TPS}, iv::Cint)
  @ccall MAD_TPSA.mad_tpsa_deriv(a::Ptr{TPS}, c::Ptr{TPS}, iv::Cint)::Cvoid
end


"""
    mad_tpsa_derivm!(a::Ptr{TPS}, c::Ptr{TPS}, n::Cint, m::Vector{Cuchar})

Differentiates TPSA with respect to the monomial defined by byte array `m`.

### Input
- `a` -- Source TPSA to differentiate
- `n` -- Length of monomial to differentiate wrt
- `m` -- Monomial to take derivative wrt

### Output
- `c` -- Destination TPSA
"""
function mad_tpsa_derivm!(a::Ptr{TPS}, c::Ptr{TPS}, n::Cint, m::Vector{Cuchar})
  @ccall MAD_TPSA.mad_tpsa_derivm(a::Ptr{TPS}, c::Ptr{TPS}, n::Cint, m::Ptr{Cuchar})::Cvoid
end


"""
    mad_tpsa_poisbra!(a::Ptr{TPS}, b::Ptr{TPS}, c::Ptr{TPS}, nv::Cint)

Sets TPSA `c` to the poisson bracket of TPSAs `a` and `b`.

### Input
- `a`  -- Source TPSA `a`
- `b`  -- Source TPSA `b`
- `nv` -- Number of variables in the TPSA

### Output
- `c`  -- Destination TPSA `c`
"""
function mad_tpsa_poisbra!(a::Ptr{TPS}, b::Ptr{TPS}, c::Ptr{TPS}, nv::Cint)
  @ccall MAD_TPSA.mad_tpsa_poisbra(a::Ptr{TPS}, b::Ptr{TPS}, c::Ptr{TPS}, nv::Cint)::Cvoid
end


"""
    mad_tpsa_taylor!(a::Ptr{TPS}, n::Cint, coef::Vector{Cdouble}, c::Ptr{TPS})

Computes the result of the Taylor series up to order `n-1` with Taylor coefficients coef for the scalar value in `a`. That is,
`c = coef[0] + coef[1]*a_0 + coef[2]*a_0^2 + ...` where `a_0` is the scalar part of TPSA `a`.

### Input
- `a`    -- TPSA `a`
- `n`    -- `Order-1` of Taylor expansion, size of `coef` array
- `coef` -- Array of coefficients in Taylor `s`
- `c`    -- Result
"""
function mad_tpsa_taylor!(a::Ptr{TPS}, n::Cint, coef::Vector{Cdouble}, c::Ptr{TPS})
  @ccall MAD_TPSA.mad_tpsa_taylor(a::Ptr{TPS}, n::Cint, coef::Ptr{Cdouble}, c::Ptr{TPS})::Cvoid
end


"""
    mad_tpsa_axpb!(a::Cdouble, x::Ptr{TPS}, b::Cdouble, r::Ptr{TPS})

`r = a*x + b`

### Input
- `a` -- Scalar `a`
- `x` -- TPSA `x`
- `b` -- Scalar `b`

### Output
- `r` -- Destination TPSA `r`
"""
function mad_tpsa_axpb!(a::Cdouble, x::Ptr{TPS}, b::Cdouble, r::Ptr{TPS})
  @ccall MAD_TPSA.mad_tpsa_axpb(a::Cdouble, x::Ptr{TPS}, b::Cdouble, r::Ptr{TPS})::Cvoid
end


"""
    mad_tpsa_axpbypc!(a::Cdouble, x::Ptr{TPS}, b::Cdouble, y::Ptr{TPS}, c::Cdouble, r::Ptr{TPS})

`r = a*x + b*y + c`

### Input
- `a` -- Scalar `a`
- `x` -- TPSA `x`
- `b` -- Scalar `b`
- `y` -- TPSA `y`
- `c` -- Scalar `c`

### Output
- `r` -- Destination TPSA `r`
"""
function mad_tpsa_axpbypc!(a::Cdouble, x::Ptr{TPS}, b::Cdouble, y::Ptr{TPS}, c::Cdouble, r::Ptr{TPS})
  @ccall MAD_TPSA.mad_tpsa_axpbypc(a::Cdouble, x::Ptr{TPS}, b::Cdouble, y::Ptr{TPS}, c::Cdouble, r::Ptr{TPS})::Cvoid
end


"""
    mad_tpsa_axypb!(a::Cdouble, x::Ptr{TPS}, y::Ptr{TPS}, b::Cdouble, r::Ptr{TPS})

`r = a*x*y + b`

### Input
- `a` -- Scalar `a`
- `x` -- TPSA `x`
- `y` -- TPSA `y`
- `b` -- Scalar `b`

### Output
- `r` -- Destination TPSA `r`
"""
function mad_tpsa_axypb!(a::Cdouble, x::Ptr{TPS}, y::Ptr{TPS}, b::Cdouble, r::Ptr{TPS})
  @ccall MAD_TPSA.mad_tpsa_axypb(a::Cdouble, x::Ptr{TPS}, y::Ptr{TPS}, b::Cdouble, r::Ptr{TPS})::Cvoid
end


"""
    mad_tpsa_axypbzpc!(a::Cdouble, x::Ptr{TPS}, y::Ptr{TPS}, b::Cdouble, z::Ptr{TPS}, c::Cdouble, r::Ptr{TPS})

`r = a*x*y + b*z + c`

### Input
- `a` -- Scalar `a`
- `x` -- TPSA `x`
- `y` -- TPSA `y`
- `b` -- Scalar `b`
- `z` -- TPSA `z`
- `c` -- Scalar `c`

### Output
- `r` -- Destination TPSA `r`
"""
function mad_tpsa_axypbzpc!(a::Cdouble, x::Ptr{TPS}, y::Ptr{TPS}, b::Cdouble, z::Ptr{TPS}, c::Cdouble, r::Ptr{TPS})
  @ccall MAD_TPSA.mad_tpsa_axypbzpc(a::Cdouble, x::Ptr{TPS}, y::Ptr{TPS}, b::Cdouble, z::Ptr{TPS}, c::Cdouble, r::Ptr{TPS})::Cvoid
end


"""
    mad_tpsa_axypbvwpc!(a::Cdouble, x::Ptr{TPS}, y::Ptr{TPS}, b::Cdouble, v::Ptr{TPS}, w::Ptr{TPS}, c::Cdouble, r::Ptr{TPS})

`r = a*x*y + b*v*w + c`

### Input
- `a` -- Scalar `a`
- `x` -- TPSA `x`
- `y` -- TPSA `y`
- `b` -- Scalar `b`
- `v` -- TPSA v
- `w` -- TPSA w
- `c` -- Scalar `c`

### Output
- `r` -- Destination TPSA `r`
"""
function mad_tpsa_axypbvwpc!(a::Cdouble, x::Ptr{TPS}, y::Ptr{TPS}, b::Cdouble, v::Ptr{TPS}, w::Ptr{TPS}, c::Cdouble, r::Ptr{TPS})
  @ccall MAD_TPSA.mad_tpsa_axypbvwpc(a::Cdouble, x::Ptr{TPS}, y::Ptr{TPS}, b::Cdouble, v::Ptr{TPS}, w::Ptr{TPS}, c::Cdouble, r::Ptr{TPS})::Cvoid
end


"""
    mad_tpsa_ax2pby2pcz2!(a::Cdouble, x::Ptr{TPS}, b::Cdouble, y::Ptr{TPS}, c::Cdouble, z::Ptr{TPS}, r::Ptr{TPS})

`r = a*x^2 + b*y^2 + c*z^2`

### Input
- `a` -- Scalar `a`
- `x` -- TPSA `x`
- `b` -- Scalar `b`
- `y` -- TPSA `y`
- `c` -- Scalar `c`
- `z` -- TPSA `z`

### Output
- `r` -- Destination TPSA `r`
"""
function mad_tpsa_ax2pby2pcz2!(a::Cdouble, x::Ptr{TPS}, b::Cdouble, y::Ptr{TPS}, c::Cdouble, z::Ptr{TPS}, r::Ptr{TPS})
  @ccall MAD_TPSA.mad_tpsa_ax2pby2pcz2(a::Cdouble, x::Ptr{TPS}, b::Cdouble, y::Ptr{TPS}, c::Cdouble, z::Ptr{TPS}, r::Ptr{TPS})::Cvoid
end


"""
    mad_tpsa_axpsqrtbpcx2!(x::Ptr{TPS}, a::Cdouble, b::Cdouble, c::Cdouble, r::Ptr{TPS})

`r = a*x + sqrt(b + c*x^2)`

### Input
- `x` -- TPSA `x`
- `a` -- Scalar `a`
- `b` -- Scalar `b`
- `c` -- Scalar `c`

### Output
- `r` -- Destination TPSA `r`
"""
function mad_tpsa_axpsqrtbpcx2!(x::Ptr{TPS}, a::Cdouble, b::Cdouble, c::Cdouble, r::Ptr{TPS})
  @ccall MAD_TPSA.mad_tpsa_axpsqrtbpcx2(x::Ptr{TPS}, a::Cdouble, b::Cdouble, c::Cdouble, r::Ptr{TPS})::Cvoid
end


"""
    mad_tpsa_logaxpsqrtbpcx2!(x::Ptr{TPS}, a::Cdouble, b::Cdouble, c::Cdouble, r::Ptr{TPS})

`r = log(a*x + sqrt(b + c*x^2))`

### Input
- `x` -- TPSA `x`
- `a` -- Scalar `a`
- `b` -- Scalar `b`
- `c` -- Scalar `c`

### Output
- `r` -- Destination TPSA `r`
"""
function mad_tpsa_logaxpsqrtbpcx2!(x::Ptr{TPS}, a::Cdouble, b::Cdouble, c::Cdouble, r::Ptr{TPS})
  @ccall MAD_TPSA.mad_tpsa_logaxpsqrtbpcx2(x::Ptr{TPS}, a::Cdouble, b::Cdouble, c::Cdouble, r::Ptr{TPS})::Cvoid
end


"""
    mad_tpsa_logxdy!(x::Ptr{TPS}, y::Ptr{TPS}, r::Ptr{TPS})

`r = log(x / y)`

### Input
- `x` -- TPSA `x`
- `y` -- TPSA `y`

### Output
- `r` -- Destination TPSA `r`
"""
function mad_tpsa_logxdy!(x::Ptr{TPS}, y::Ptr{TPS}, r::Ptr{TPS})
  @ccall MAD_TPSA.mad_tpsa_logxdy(x::Ptr{TPS}, y::Ptr{TPS}, r::Ptr{TPS})::Cvoid
end


"""
    mad_tpsa_vec2fld!(na::Cint, a::Ptr{TPS}, mc::Vector{Ptr{TPS}})

Assuming the variables in the TPSA are canonically-conjugate, and ordered so that the canonically-
conjugate variables are consecutive (q1, p1, q2, p2, ...), calculates the vector field (Hamilton's 
equations) from the passed Hamiltonian, defined as `[da/dp1, -da/dq1, ...]`

### Input
- `na`  -- Number of TPSA in `mc` consistent with number of variables in `a`
- `a`   -- Hamiltonian as a TPSA

### Output
- `mc`  -- Vector field derived from `a` using Hamilton's equations 
"""
function mad_tpsa_vec2fld!(na::Cint, a::Ptr{TPS}, mc::Vector{Ptr{TPS}})
  @ccall MAD_TPSA.mad_tpsa_vec2fld(na::Cint, a::Ptr{TPS}, mc::Ptr{Ptr{TPS}})::Cvoid
end


"""
    mad_tpsa_fld2vec!(na::Cint, ma::Vector{Ptr{TPS}}, c::Ptr{TPS})

Assuming the variables in the TPSA are canonically-conjugate, and ordered so that the canonically-
conjugate variables are consecutive (q1, p1, q2, p2, ...), calculates the Hamiltonian one obtains 
from ther vector field (in the form `[da/dp1, -da/dq1, ...]`)

### Input
- `na`  -- Number of TPSA in `ma` consistent with number of variables in `c`
- `ma`  -- Vector field 

### Output
- `c`   -- Hamiltonian as a TPSA derived from the vector field `ma`
"""
function mad_tpsa_fld2vec!(na::Cint, ma::Vector{Ptr{TPS}}, c::Ptr{TPS})
  @ccall MAD_TPSA.mad_tpsa_fld2vec(na::Cint, ma::Ptr{Ptr{TPS}}, c::Ptr{TPS})::Cvoid
end


"""
    mad_tpsa_fgrad!(na::Cint, ma::Vector{Ptr{TPS}}, b::Ptr{TPS}, c::Ptr{TPS})

Calculates `dot(ma, grad(b))`

### Input
- `na` -- Length of `ma` consistent with number of variables in `b`
- `ma` -- Vector of TPSA
- `b`  -- TPSA

### Output
- `c`  -- `dot(ma, grad(b))`
"""
function mad_tpsa_fgrad!(na::Cint, ma::Vector{Ptr{TPS}}, b::Ptr{TPS}, c::Ptr{TPS})
  @ccall MAD_TPSA.mad_tpsa_fgrad(na::Cint, ma::Ptr{Ptr{TPS}}, b::Ptr{TPS}, c::Ptr{TPS})::Cvoid
end


"""
    mad_tpsa_liebra!(na::Cint, ma::Vector{Ptr{TPS}}, mb::Vector{Ptr{TPS}}, mc::Vector{Ptr{TPS}})

Computes the Lie bracket of the vector fields `ma` and `mb`, defined as 
sum_i ma_i (dmb/dx_i) - mb_i (dma/dx_i).

### Input
- `na` -- Length of `ma` and `mb`
- `ma` -- Vector of TPSA `ma`
- `mb` -- Vector of TPSA `mb`

### Output
- `mc` -- Destination vector of TPSA `mc`
"""
function mad_tpsa_liebra!(na::Cint, ma::Vector{Ptr{TPS}}, mb::Vector{Ptr{TPS}}, mc::Vector{Ptr{TPS}})
  @ccall MAD_TPSA.mad_tpsa_liebra(na::Cint, ma::Ptr{Ptr{TPS}}, mb::Ptr{Ptr{TPS}}, mc::Ptr{Ptr{TPS}})::Cvoid
end


"""
    mad_tpsa_exppb!(na::Cint, ma::Vector{Ptr{TPS}}, mb::Vector{Ptr{TPS}}, mc::Vector{Ptr{TPS}})

Computes the exponential of fgrad of the vector fields `ma` and `mb`,
literally `exppb(ma, mb) = mb + fgrad(ma, mb) + fgrad(ma, fgrad(ma, mb))/2! + ...`

### Input
- `na` -- Length of `ma` and `mb`
- `ma` -- Vector of TPSA `ma`
- `mb` -- Vector of TPSA `mb`

### Output
- `mc` -- Destination vector of TPSA `mc`
"""
function mad_tpsa_exppb!(na::Cint, ma::Vector{Ptr{TPS}}, mb::Vector{Ptr{TPS}}, mc::Vector{Ptr{TPS}})
  @ccall MAD_TPSA.mad_tpsa_exppb(na::Cint, ma::Ptr{Ptr{TPS}}, mb::Ptr{Ptr{TPS}}, mc::Ptr{Ptr{TPS}})::Cvoid
end


"""
    mad_tpsa_logpb!(na::Cint, ma::Vector{Ptr{TPS}}, mb::Vector{Ptr{TPS}}, mc::Vector{Ptr{TPS}})

Computes the log of the Poisson bracket of the vector of TPSA `ma` and `mb`; the result 
is the vector field `F` used to evolve to `ma` from `mb`.

### Input
- `na` -- Length of `ma` and `mb`
- `ma` -- Vector of TPSA `ma`
- `mb` -- Vector of TPSA `mb`

### Output
- `mc` -- Destination vector of TPSA `mc`
"""
function mad_tpsa_logpb!(na::Cint, ma::Vector{Ptr{TPS}}, mb::Vector{Ptr{TPS}}, mc::Vector{Ptr{TPS}})
  @ccall MAD_TPSA.mad_tpsa_logpb(na::Cint, ma::Ptr{Ptr{TPS}}, mb::Ptr{Ptr{TPS}}, mc::Ptr{Ptr{TPS}})::Cvoid
end


"""
    mad_tpsa_mord(na::Cint, ma::Vector{Ptr{TPS}}, hi::Bool)::Cuchar

If `hi` is false, getting the maximum `mo` among all TPSAs in `ma`. 
If `hi` is `true`, gets the maximum `hi` of the map instead of `mo`

### Input
- `na` -- Length of map `ma`
- `ma` -- Map (vector of TPSAs)
- `hi` -- If `true`, returns maximum `hi`, else returns maximum `mo` of the map

### Output
- `ret` -- Maximum `hi` of the map if `hi` is `true`, else returns maximum `mo` of the map
"""
function mad_tpsa_mord(na::Cint, ma::Vector{Ptr{TPS}}, hi::Bool)::Cuchar
  ret = @ccall MAD_TPSA.mad_tpsa_mord(na::Cint, ma::Ptr{Ptr{TPS}}, hi::Bool)::Cuchar
  return ret
end


"""
    mad_tpsa_mnrm(na::Cint, ma::Vector{Ptr{TPS}})::Cdouble

Computes the norm of the map (sum of absolute value of coefficients of all TPSAs in the map).

### Input
- `na`  -- Number of TPSAs in the map
- `ma`  -- map `ma`

### Output
- `nrm` -- Norm of map (sum of absolute value of coefficients of all TPSAs in the map)
"""
function mad_tpsa_mnrm(na::Cint, ma::Vector{Ptr{TPS}})::Cdouble
  nrm = @ccall MAD_TPSA.mad_tpsa_mnrm(na::Cint, ma::Ptr{Ptr{TPS}})::Cdouble
  return nrm
end


"""
    mad_tpsa_minv!(na::Cint, ma::Vector{Ptr{TPS}}, nb::Cint, mc::Vector{Ptr{TPS}})

Inverts the map. To include the parameters in the inversion, `na` = `nn` and the output map 
length only need be `nb` = `nv`.

### Input
- `na` -- Input map length (should be `nn` to include parameters)
- `ma` -- Map `ma`
- `nb` -- Output map length (generally = `nv`)

### Output
- `mc` -- Inversion of map `ma`
"""
function mad_tpsa_minv!(na::Cint, ma::Vector{Ptr{TPS}}, nb::Cint, mc::Vector{Ptr{TPS}})
  @ccall MAD_TPSA.mad_tpsa_minv(na::Cint, ma::Ptr{Ptr{TPS}}, nb::Cint, mc::Ptr{Ptr{TPS}})::Cvoid
end


"""
    mad_tpsa_pminv!(na::Cint, ma::Vector{Ptr{TPS}}, nb::Cint, mc::Vector{Ptr{TPS}}, select::Vector{Cint})

Computes the partial inverse of the map with only the selected variables, specified by 0s or 1s in select.
To include the parameters in the inversion, `na` = `nn` and the output map length only need be `nb` = `nv`.

### Input
- `na` -- Input map length (should be `nn` to include parameters)
- `ma` -- Map `ma`
- `nb` -- Output map length (generally = `nv`)
- `select` -- Array of 0s or 1s defining which variables to do inverse on (atleast same size as na)'

### Output
- `mc`     -- Partially inverted map using variables specified as 1 in the select array
"""
function mad_tpsa_pminv!(na::Cint, ma::Vector{Ptr{TPS}}, nb::Cint, mc::Vector{Ptr{TPS}}, select::Vector{Cint})
  @ccall MAD_TPSA.mad_tpsa_pminv(na::Cint, ma::Ptr{Ptr{TPS}}, nb::Cint, mc::Ptr{Ptr{TPS}}, select::Ptr{Cint})::Cvoid
end


"""
    mad_tpsa_compose!(na::Cint, ma::Vector{Ptr{TPS}}, nb::Cint, mb::Vector{Ptr{TPS}}, mc::Vector{Ptr{TPS}})

Composes two maps.

### Input
- `na` -- Number of TPSAs in map `ma`
- `ma` -- map `ma`
- `nb` -- Number of TPSAs in map `mb`
- `mb` -- map `mb`

### Output
- `mc` -- Composition of maps `ma` and `mb`
"""
function mad_tpsa_compose!(na::Cint, ma::Vector{Ptr{TPS}}, nb::Cint, mb::Vector{Ptr{TPS}}, mc::Vector{Ptr{TPS}})
  @ccall MAD_TPSA.mad_tpsa_compose(na::Cint, ma::Ptr{Ptr{TPS}}, nb::Cint, mb::Ptr{Ptr{TPS}}, mc::Ptr{Ptr{TPS}})::Cvoid
end


"""
    mad_tpsa_translate!(na::Cint, ma::Vector{Ptr{TPS}}, nb::Cint, tb::Vector{Cdouble}, mc::Vector{Ptr{TPS}})

Translates the expansion point of the map by the amount `tb`.

### Input
- `na` -- Number of TPSAS in the map
- `ma` -- map `ma`
- `nb` -- Length of `tb`
- `tb` -- Vector of amount to translate for each variable

### Output
- `mc` -- Map evaluated at the new point translated `tb` from the original evaluation point
"""
function mad_tpsa_translate!(na::Cint, ma::Vector{Ptr{TPS}}, nb::Cint, tb::Vector{Cdouble}, mc::Vector{Ptr{TPS}})
  @ccall MAD_TPSA.mad_tpsa_translate(na::Cint, ma::Ptr{Ptr{TPS}}, nb::Cint, tb::Ptr{Cdouble}, mc::Ptr{Ptr{TPS}})::Cvoid
end


"""
    mad_tpsa_eval!(na::Cint, ma::Vector{Ptr{TPS}}, nb::Cint, tb::Vector{Cdouble}, tc::Vector{Cdouble})

Evaluates the map at the point `tb`

### Input
- `na` -- Number of TPSAs in the map
- `ma` -- map `ma`
- `nb` -- Length of `tb`
- `tb` -- Point at which to evaluate the map

### Output
- `tc` -- Values for each TPSA in the map evaluated at the point `tb`
"""
function mad_tpsa_eval!(na::Cint, ma::Vector{Ptr{TPS}}, nb::Cint, tb::Vector{Cdouble}, tc::Vector{Cdouble})
  @ccall MAD_TPSA.mad_tpsa_eval(na::Cint, ma::Ptr{Ptr{TPS}}, nb::Cint, tb::Ptr{Cdouble}, tc::Ptr{Cdouble})::Cvoid
end


"""
    mad_tpsa_mconv!(na::Cint, ma::Vector{Ptr{TPS}}, nc::Cint, mc::Vector{Ptr{TPS}}, n::Cint, t2r_::Vector{Cint}, pb::Cint)

Equivalent to `mad_tpsa_convert`, but applies the conversion to all TPSAs in the map `ma`.

### Input
- `na`   -- Number of TPSAs in the map
- `ma`   -- map `ma`
- `nc`   -- Number of TPSAs in the output map `mc`
- `n`    -- Length of vector (size of `t2r_`)
- `t2r_` -- (Optional) Vector of index lookup
- `pb`   -- Poisson bracket, 0, 1:fwd, -1:bwd

### Output
- `mc`   -- map `mc` with specified conversions 
"""
function mad_tpsa_mconv!(na::Cint, ma::Vector{Ptr{TPS}}, nc::Cint, mc::Vector{Ptr{TPS}}, n::Cint, t2r_::Vector{Cint}, pb::Cint)
  @ccall MAD_TPSA.mad_tpsa_mconv(na::Cint, ma::Ptr{Ptr{TPS}}, nc::Cint, mc::Ptr{Ptr{TPS}}, n::Cint, t2r_::Ptr{Cint}, pb::Cint)::Cvoid
end


"""
    mad_tpsa_print(t::Ptr{TPS}, name_::Cstring, eps_::Cdouble, nohdr_::Cint, stream_::Ptr{Cvoid})

Prints the TPSA coefficients with precision `eps_`. If `nohdr_` is not zero, 
the header is not printed. 

### Input
- `t`       -- TPSA to print
- `name_`   -- (Optional) Name of TPSA
- `eps_`    -- (Optional) Precision to output
- `nohdr_`  -- (Optional) If True, no header is printed
- `stream_` -- (Optional) `FILE` pointer of output stream. Default is `stdout`
"""
function mad_tpsa_print(t::Ptr{TPS}, name_, eps_::Cdouble, nohdr_::Cint, stream_::Ptr{Cvoid})
  @ccall MAD_TPSA.mad_tpsa_print(t::Ptr{TPS}, name_::Cstring, eps_::Cdouble, nohdr_::Cint, stream_::Ptr{Cvoid})::Cvoid
end


"""
    mad_tpsa_scan(stream_::Ptr{Cvoid})::Ptr{TPS}

Scans in a TPSA from the `stream_`.

### Input
- `stream_` -- (Optional) I/O stream from which to read the TPSA, default is `stdin`

### Output
- `t`       -- TPSA scanned from I/O `stream_`
"""
function mad_tpsa_scan(stream_::Ptr{Cvoid})::Ptr{TPS}
  t = @ccall MAD_TPSA.mad_tpsa_scan(stream_::Ptr{Cvoid})::Ptr{TPS}
  return t
end


"""
    mad_tpsa_scan_hdr(kind_::Ref{Cint}, name_::Ptr{Cuchar}, stream_::Ptr{Cvoid})::Ptr{Desc}

Read TPSA header. Returns descriptor for TPSA given the header. This is useful for external languages using 
this library where the memory is managed NOT on the C side.

### Input
- `kind_`   -- (Optional) Real or complex TPSA, or detect automatically if not provided.
- `name_`   -- (Optional) Name of TPSA
- `stream_` -- (Optional) I/O stream to read TPSA from,  default is `stdin`

### Output
- `ret`     -- Descriptor for the TPSA 
"""
function mad_tpsa_scan_hdr(kind_::Ref{Cint}, name_::Ptr{Cuchar}, stream_::Ptr{Cvoid})::Ptr{Desc}
  desc = @ccall MAD_TPSA.mad_tpsa_scan_hdr(kind_::Ptr{Cint}, name_::Ptr{Cuchar}, stream_::Ptr{Cvoid})::Ptr{Desc}
  return ret
end


"""
    mad_tpsa_scan_coef!(t::Ptr{TPS}, stream_::Ptr{Cvoid})

Read TPSA coefficients into TPSA `t`. This should be used with `mad_tpsa_scan_hdr` for external languages using 
this library where the memory is managed NOT on the C side.

### Input
- `stream_` -- (Optional) I/O stream to read TPSA from,  default is `stdin`

### Output
- `t`       -- TPSA with coefficients scanned from `stream_`
"""
function mad_tpsa_scan_coef!(t::Ptr{TPS}, stream_::Ptr{Cvoid})
  @ccall MAD_TPSA.mad_tpsa_scan_coef(t::Ptr{TPS}, stream_::Ptr{Cvoid})::Cvoid
end


"""
    mad_tpsa_debug(t::Ptr{TPS}, name_::Cstring, fnam_::Cstring, line_::Cint, stream_::Ptr{Cvoid})::Cint

Prints TPSA with all information of data structure.

### Input
- `t`       -- TPSA
- `name_`   -- (Optional) Name of TPSA
- `fnam_`   -- (Optional) File name to print to
- `line_`   -- (Optional) Line number in file to start at
- `stream_` -- (Optional) I/O stream to print to, default is `stdout`

### Output
- `ret` -- ??
"""
function mad_tpsa_debug(t::Ptr{TPS}, name_::Cstring, fnam_::Cstring, line_::Cint, stream_::Ptr{Cvoid})::Cint
  ret = @ccall MAD_TPSA.mad_tpsa_debug(t::Ptr{TPS}, name_::Cstring, fnam_::Cstring, line_::Cint, stream_::Ptr{Cvoid})::Cint
  return ret
end


"""
    mad_tpsa_prtdensity(stream_::Ptr{Cvoid})

???
"""
function mad_tpsa_prtdensity(stream_::Ptr{Cvoid})
  @ccall MAD_TPSA.mad_tpsa_prtdensity(stream_::Ptr{Cvoid})::Cvoid
end

"""
    mad_tpsa_clrdensity!()::Cvoid

???
"""
function mad_tpsa_clrdensity!()::Cvoid
  @ccall MAD_TPSA.mad_tpsa_clrdensity()::Cvoid
end

"""
    mad_tpsa_isval(t::Ptr{TPS})::Bool

Sanity check of the TPSA integrity.

### Input
- `t` -- TPSA to check if valid

### Output
- `ret`  -- True if valid TPSA, false otherwise
"""
function mad_tpsa_isval(t::Ptr{TPS})::Bool
  ret = @ccall MAD_TPSA.mad_tpsa_isval(t::Ptr{TPS})::Bool
  return ret
end

"""
    mad_tpsa_isvalid(t::Ptr{TPS})::Bool

Sanity check of the TPSA integrity.

### Input
- `t` -- TPSA to check if valid

### Output
- `ret`  -- True if valid TPSA, false otherwise
"""
function mad_tpsa_isvalid(t::Ptr{TPS})::Bool
  ret = @ccall MAD_TPSA.mad_tpsa_isvalid(t::Ptr{TPS})::Bool
  return ret
end


"""
    mad_tpsa_density(t::Ptr{TPS})::Cdouble

???
"""
function mad_tpsa_density(t::Ptr{TPS})::Cdouble
  ret = @ccall MAD_TPSA.mad_tpsa_density(t::Ptr{TPS})::Cdouble
  return ret
end


"""
    mad_tpsa_init(t::Ptr{TPS}, d::Ptr{Desc}, mo::Cuchar)::Ptr{TPS}

Unsafe initialization of an already existing TPSA `t` with maximum order `mo` to the descriptor `d`. `mo` must be less than 
the maximum order of the descriptor. `t` is modified in place and also returned.

### Input
- `t`  -- TPSA to initialize to descriptor `d`
- `d`  -- Descriptor
- `mo` -- Maximum order of the TPSA (must be less than maximum order of the descriptor)

### Output
- `t`  -- TPSA initialized to descriptor `d` with maximum order `mo`
"""
function mad_tpsa_init!(t::Ptr{TPS}, d::Ptr{Desc}, mo::Cuchar)::Ptr{TPS}
  t = @ccall MAD_TPSA.mad_tpsa_init(t::Ptr{TPS}, d::Ptr{Desc}, mo::Cuchar)::Ptr{TPS}
  return t
end

