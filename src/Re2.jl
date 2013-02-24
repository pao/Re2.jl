module Re2

export Regex2, match, @r2_str

import Base.show
import Base.match

include("cre2.jl")

type Regex2
    pattern::ByteString
    regex::Ptr{Void}

    function Regex2(pattern::String)
        regex = cre2.new(pattern)
        new(pattern, regex)
    end
end

macro r2_str(pattern) Regex2(pattern) end

function show(io::IO, re::Regex2)
    print(io, "Regex2(", re.pattern, ")")
end

function match(re::Regex2, str::ByteString) #TODO: whatever idx does
    m, n = cre2.match(re.regex, str)

    # shamelessly copied from regex.jl's match
    if isempty(m); return nothing; end
    mat = str[m[1]+1:m[2]]
    cap = Union(Nothing,ByteString)[
            m[2i+1] < 0 ? nothing : str[m[2i+1]+1:m[2i+2]] for i=1:n ]
    off = [ m[2i+1]::Int+1 for i=1:n ]
    RegexMatch(mat, cap, m[1]+1, off)
end
match(r::Regex2, s::String) =
    error("regex matching is only available for bytestrings; use bytestring(s) to convert")

end