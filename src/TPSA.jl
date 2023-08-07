module TPSA
include("Descriptor.jl")
include("RealTPSA.jl")
include("ComplexTPSA.jl")
using .Descriptor
using .RealTPSA
using .ComplexTPSA
using Printf
#import Base: sin
export Desc, RTPSA, CTPSA, new_desc,new_TPSA,set_TPSA!,print_TPSA,sin!,del!,asin!,set_name,cleanup,print_TPSA_mad,MAD_TPSA_DEFAULT, MAD_TPSA_SAME

const MAD_TPSA = :("libmad_tpsa")
const MAD_TPSA_DEFAULT::Cuchar = 255
const MAD_TPSA_SAME::Cuchar = 254

"""
    new_desc(nv::Integer, mo::Integer)::Ptr{Desc{RTPSA,CTPSA}}

  Creates a TPSA descriptor with the specified number of variables and maximum order. 
  The number of parameters is set to 0. 

  Input:
    nv -- Number of variables 
    mo -- Maximum order, must be between 0 and 255 (UInt8) for safe conversion to C

  Output:
    A pointer to the TPSA descriptor created, with:
    Desc.nv = nv 
    Desc.mo = mo
"""
function new_desc(nv::Integer, mo::Integer)::Ptr{Desc{RTPSA,CTPSA}}
  d = @ccall MAD_TPSA.mad_desc_newv(nv::Cint,mo::Cuchar)::Ptr{Desc{RTPSA,CTPSA}}
  return d
end


"""
    new_desc(nv::Integer, mo::Integer, np::Integer, po::Integer)::Ptr{Desc{RTPSA,CTPSA}}

  Creates a TPSA descriptor with the specifed number of variables, maximum order,
  number of parameters, and parameter order.
  
  Input:
    nv -- Number of variables 
    mo -- Maximum order, must be between 0 and 255 (UInt8) for safe conversion to C
    np -- Number of parameters
    po -- Parameter order,  must be between 0 and 255 (UInt8) for safe conversion to C

  Output:
    A pointer to the TPSA descriptor created, with:
    Desc.nv = nv 
    Desc.mo = mo
    Desc.np = np
    Desc.po = po
"""
function new_desc(nv::Integer, mo::Integer, np::Integer, po::Integer)::Ptr{Desc{RTPSA,CTPSA}}
  d = @ccall MAD_TPSA.mad_desc_newvp(nv::Cint, mo::Cuchar, np::Cint, po::Cuchar)::Ptr{Desc{RTPSA,CTPSA}}
  return d
end

"""
  new_desc(nv::Integer, mo::Integer, np::Integer, po::Integer,no::Vector{<:UInt8})::Ptr{Desc{RTPSA,CTPSA}}

Creates a TPSA descriptor with the specifed number of variables, maximum order,
number of parameters, parameter order, and individual variable/parameter orders 
specified in no. The first nv entries in no correspond to the variables' orders 
and the next np entries correspond the parameters' orders.

Input:
  nv -- Number of variables 
  mo -- Maximum order
  np -- Number of parameters
  po -- Parameter order
  no -- Vector of variable and parameter orders, in order. Must be length nv+np (FIGURE OUT order). 

Output:
  A pointer to the TPSA descriptor created, with:
  Desc.nv = nv 
  Desc.mo = mo
  Desc.np = np
  Desc.po = po
  Desc.no = no
"""
function new_desc(nv::Integer, mo::Integer, np::Integer, po::Integer, no::Vector{<:UInt8})::Ptr{Desc{RTPSA,CTPSA}}
  d = @ccall MAD_TPSA.mad_desc_newvpo(nv::Cint, mo::Cuchar, np::Cint, po::Cuchar, no::Ptr{Cuchar})::Ptr{Desc{RTPSA,CTPSA}}
  return d
end


"""
    new_TPSA(d::Ptr{Desc{RTPSA,CTPSA}}, mo::Integer)::Ptr{RTPSA{Desc}}

  Creates a real TPSA defined by the specified descriptor and maximum order.
  If mad_tpsa_default is passed for mo, the mo defined in the descriptor is used.
  
  Input:
    d  -- Descriptor for TPSA
    mo -- Maximum order of TPSA

  Output:
    A pointer to the real TPSA created, with:
    RTPSA.d   = d 
    RTPSA.mo  = mo
    and all other members initialized to 0.
"""
function new_TPSA(d::Ptr{Desc{RTPSA,CTPSA}}, mo::Integer)::Ptr{RTPSA{Desc}}
  @ccall MAD_TPSA.mad_tpsa_newd(d::Ptr{Desc{RTPSA,CTPSA}},mo::Cuchar)::Ptr{RTPSA{Desc}}
end

"""
    new_TPSA(t::Ptr{RTPSA{Desc}}, mo::Integer)::Ptr{RTPSA{Desc}}

  Creates a real TPSA copy of the inputted TPSA, with maximum order specified by mo.
  If mad_tpsa_same is passed for mo, the mo currently in t is used for the created TPSA.
  
  Input:
    t  -- Pointer to real TPSA to copy
    mo -- Maximum order of new TPSA

  Output:
    A pointer to the real TPSA copy created with maximum order mo.
"""
function new_TPSA(t::Ptr{RTPSA{Desc}}, mo::Integer)::Ptr{RTPSA{Desc}}
  @ccall MAD_TPSA.mad_tpsa_new(t::Ptr{RTPSA{Desc}}, mo::Cuchar)::Ptr{RTPSA{Desc}}
end

"""
    set_TPSA(t::Ptr{RTPSA{Desc}}, i::Integer, n::Integer, v::Vector{<:Float64})

  Sets the coefficients of the TPSA in indices i:i+n to those in v. That is,
  t.coefs[i:i+n] = v. v must be length n.
  
  Input:
    t -- Pointer to real TPSA
    i -- Starting index of coefficients in TPSA to set
    n -- Number of coefficients to set in TPSA
    v -- Vector values to set coefficients in TPSA. 

  Output:
    Sets the coefficients in the TPSA t accordingly. 
"""
function set_TPSA!(t::Ptr{RTPSA{Desc}}, i::Integer, n::Integer, v::Vector{<:Float64})
  @ccall MAD_TPSA.mad_tpsa_setv(t::Ptr{RTPSA{Desc}}, i::Cint, n::Cuint, v::Ptr{Cdouble})::Cvoid
end

"""
NOTE: THIS WILL BE REWRITTEN IN JULIA AND WILL PRINT TO FILES AS WELL.

    print_TPSA(t::Ptr{RTPSA{Desc}}, name::AbstractString, eps_::Real,nohdr_::Integer)

  Prints the TPSA coefficients to stdout with precision eps_. If nohdr_ is not zero, 
  the header is not printed. 
"""
function print_TPSA(t::Ptr{RTPSA{Desc}}, name::AbstractString, eps_::Real, nohdr_::Bool = false)
  #@ccall MAD_TPSA.mad_tpsa_print(t::Ptr{RTPSA{Desc}}, name::Cstring, eps_::Cint,nohdr_::Cint,0::Cint)::Cvoid
  t_val =  unsafe_load(t)
  d_val = unsafe_load(Ptr{Desc{RTPSA,CTPSA}}(t_val.d))
  if (!nohdr_)
    if (d_val.np!=0 || d_val.uno!=0) 
      @printf("\n %-8s:  %c, NV = %3d, MO = %2hhu, NP = %3d, PO = %2hhu", name, "R", d_val.nv, d_val.mo, d_val.np, d_val.po)
    else
      @printf("\n %-8s:  %c, NV = %3d, MO = %2hhu", name, "R", d_val.nv, d_val.mo)
    end

    no = unsafe_wrap(Vector{UInt8}, d_val.no, d_val.np+d_val.nv)
    if (d_val.uno != 0) # If user defined order for each var/param:
      print(", NO = ")
      # print variables
      for i=1:2:d_val.nv-1
        @printf("  %hhu %hhu", no[i], no[i+1])
      end
      if (d_val.nv % 2 == 1)
        @printf("  %hhu", no[nv])
      end

      # print parameters
      for i = d_val.nv+1:1:d_val.nv+d_val.np
        if (no[i] != d_val.po)
          @printf("  %d^%hhu", i+1, no[i])
        end
      end
    end
    @printf("\n *******************************************************")
  end
  @ccall MAD_TPSA.mad_tpsa_update0(t::Ptr{RTPSA{Desc}}, t_val.lo::Cuchar, t_val.hi::Cuchar)::Ptr{RTPSA{Desc}}
  t_val =  unsafe_load(t)
  if (t_val.nz != 0)
    # print the coefficients
    o2i = d_val.ord2
  end

end

function print_TPSA_mad(t::Ptr{RTPSA{Desc}}, name::AbstractString, eps_::Real,nohdr_::Integer)
  @ccall MAD_TPSA.mad_tpsa_print(t::Ptr{RTPSA{Desc}}, name::Cstring, eps_::Cint,nohdr_::Cint,0::Cint)::Cvoid
end


function set_name(t::Ptr{RTPSA{Desc}}, nam::AbstractString)
  @ccall MAD_TPSA.mad_tpsa_setnam(t::Ptr{RTPSA{Desc}}, nam::Cstring)::Cvoid
end


"""
    sin!(a::Ptr{RTPSA{Desc}}, c::Ptr{RTPSA{Desc}})

  Sets c = sin(a) in place. Aliasing is supported (i.e. a == c).

  Input:
    a -- Source TPSA 
    c -- Destination TPSA

  Output:
    Sets the TPSA c = sin(a).
"""
function sin!(a::Ptr{RTPSA{Desc}}, c::Ptr{RTPSA{Desc}})
  @ccall MAD_TPSA.mad_tpsa_sin(a::Ptr{RTPSA{Desc}}, c::Ptr{RTPSA{Desc}})::Cvoid
end

"""
    asin!(a::Ptr{RTPSA{Desc}}, c::Ptr{RTPSA{Desc}})

  Sets c = asin(a) in place. Aliasing is supported (i.e. a == c).

  Input:
    a -- Source TPSA 
    c -- Destination TPSA

  Output:
    Sets the TPSA c = asin(a).
"""
function asin!(a::Ptr{RTPSA{Desc}}, c::Ptr{RTPSA{Desc}})
  @ccall "libmad_tpsa".mad_tpsa_asin(a::Ptr{RTPSA{Desc}}, c::Ptr{RTPSA{Desc}})::Cvoid 
end

"""
    del!(t::Ptr{RTPSA{Desc}})

  Destroys the TPSA at t.

  Input:
    t -- TPSA to destroy

  Output:
    None.
"""
function del!(t::Ptr{RTPSA{Desc}})
  @ccall MAD_TPSA.mad_tpsa_del(t::Ptr{RTPSA{Desc}})::Cvoid
end

"""
    del!(d::Ptr{Desc{RTPSA,CTPSA}})

  Destroys the descriptor d.
  
  Input:
    d -- Descriptor to destroy

  Output:
    None.
"""
function del!(d::Ptr{Desc{RTPSA,CTPSA}})
  @ccall "libmad_tpsa".mad_desc_del(d::Ptr{Desc{RTPSA,CTPSA}})::Cvoid
end

"""
    cleanup()

  Destroys all descriptors.
"""
function cleanup()
  @ccall "libmad_tpsa".mad_desc_del(0::Cint)::Cvoid
end

end
