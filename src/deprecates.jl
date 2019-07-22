import Base.@deprecate

import Base:
    dirname,
    ispath,
    realpath,
    normpath,
    abspath,
    relpath,
    filemode,
    isabspath,
    mkpath,
    mv,
    rm

@deprecate dirname(fp::AbstractPath) parent(fp)
@deprecate ispath(fp::AbstractPath) exists(fp)
@deprecate realpath(fp::AbstractPath) real(fp)
@deprecate normpath(fp::AbstractPath) norm(fp)
@deprecate abspath(fp::AbstractPath) abs(fp)
@deprecate relpath(fp::AbstractPath) relative(fp)
@deprecate filemode(fp::AbstractPath) mode(fp)
@deprecate isabspath(fp::AbstractPath) isabs(fp)
@deprecate mkpath(fp::AbstractPath) mkdir(fp; recursive=true, exist_ok=true)
@deprecate parts(fp::AbstractPath) fp.segments
@deprecate drive(fp::Abstractpath) fp.drive
@deprecate root(fp::AbstractPath) fp.root
@deprecate anchor(fp::AbstractPath) fp.anchor
