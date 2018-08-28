cd(abs(parent(Path(@__FILE__)))) do
	@testset "UNC Path Usage" begin

		p1 = UNCPath(tuple(["\\\\", "foo", "bar"]...))
		@test p1.parts == ("\\\\", "foo", "bar")

		p2 = UNCPath(tuple(["foo", "bar"]...))
		@test p2.parts == ("foo", "bar")

	end
end