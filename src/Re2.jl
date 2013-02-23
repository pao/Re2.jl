module Re2

module cre2 # low level interface

using StrPack

libcre2 = dlopen(joinpath(Pkg.dir("Re2"), "deps/cre2-0.1b3/=build/src/.libs/libcre2.so"))
macro cre2(fun)
    :(dlsym(libcre2, $fun))
end

const CRE2_VERSION = bytestring(ccall(@cre2(:cre2_version_string), Ptr{Uint8}, ()))

macro optflag(optname)
    fname = symbol("opt_set_"*optname)
    fsym = "cre2_opt_set_"*optname
    :(($(esc(fname)))(opt::Ptr{Void}, flag::Bool) = ccall(@cre2($fsym), Void, (Ptr{Void}, Int32), opt, flag?1:0))
end

@optflag "posix_syntax"
@optflag "longest_match"
@optflag "log_errors"
@optflag "literal"
@optflag "never_nl"
@optflag "case_sensitive"
@optflag "perl_classes"
@optflag "word_boundary"
@optflag "one_line"


function new(pattern::String, options::Ptr{Void})
    rex = ccall(@cre2(:cre2_new), Ptr{Void},
                (Ptr{Uint8}, Int32, Ptr{Void}),
                pattern, length(convert(Array{Uint8}, pattern)), options)
    finalizer(rex, (r)->ccall(@cre2(:cre2_delete), Void, (Ptr{Void},), r))
    errstr = bytestring(ccall(@cre2(:cre2_error_string), Ptr{Uint8}, (Ptr{Void},), rex))
    if !isempty(errstr)
        error(errstr)
    end
    rex
end
new(pattern::String) = new(pattern, opt_new())

function opt_new()
    opt = ccall(@cre2(:cre2_opt_new), Ptr{Void}, ())
    finalizer(opt, (o)->ccall(@cre2(:cre2_opt_delete), Void, (Ptr{Void},), o))
    opt_set_log_errors(opt, false)
    opt
end

@struct type cre2_string_t
    data::Ptr
    length::Int32
end

function match(rex::Ptr{Void}, text::String)
    text_len = length(convert(Array{Uint8}, text))
    nmatch = 1 + ccall(@cre2(:cre2_num_capturing_groups), Int32, (Ptr{Void},), rex)
    matches = Array(Uint8, nmatch*(StrPack.calcsize(cre2_string_t)))
    n = ccall(@cre2(:cre2_match), Int32,
              (Ptr{Void}, Ptr{Uint8}, Int32, Int32, Int32, Int32, Ptr{Uint8}, Int32),
              rex, text, text_len, 0, text_len, 1, matches, nmatch)
    if n == 0
        return false
    end
    true
    ranges = Array(Int, nmatch*2)
    ccall(@cre2(:cre2_strings_to_ranges), Void,
          (Ptr{Uint8}, Ptr{Int}, Ptr{Uint8}, Int32),
          text, ranges, matches, nmatch)
    ranges
end

end

end