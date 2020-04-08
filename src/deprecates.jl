import Base.@deprecate

import Base: real, abs, size

@deprecate real(fp::AbstractPath) canonicalize(fp)
@deprecate abs(fp::AbstractPath) absolute(fp)
@deprecate isabs(fp::AbstractPath) isabsolute(fp)
