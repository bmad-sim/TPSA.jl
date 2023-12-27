using Test
using GTPSA

@testset "Compare with MAD" begin
  include("compare_MAD.jl")
  expected_out = """mad_mono.h downloaded.
  Comparing mad_mono.h to mono.jl...
  mad_desc.h downloaded.
  Comparing mad_desc.h to desc.jl...
  mad_tpsa.h downloaded.
  Comparing mad_tpsa.h to rtpsa.jl...
  mad_tpsa_ordv: Variable in C tpsa_t* ... => ...::Ptr{RTPSA} not equal to Julia ts::Ptr{RTPSA}...
  mad_ctpsa.h downloaded.
  Comparing mad_ctpsa.h to ctpsa.jl...
  mad_ctpsa_ordv: Variable in C ctpsa_t* ... => ...::Ptr{CTPSA} not equal to Julia ts::Ptr{CTPSA}...
  mad_ctpsa_equt: Variable in C num_t tol => tol::Cdouble not equal to Julia tol_::Cdouble
  mad_ctpsa_unit: Variable in C ctpsa_t* x => x::Ptr{CTPSA} not equal to Julia t::Ptr{CTPSA}
  """
  @test compare_MAD() == expected_out
end