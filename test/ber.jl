@testset "tag class" begin
    @testset "class universal" begin
        test_vector = [0b00000001, 0b00000000]
        wanted_tag = ASN1.ASNTag(0x0, false, Bool[0, 0, 0, 0, 1], 0, UInt8[])
        result = ASN1.parse_tag(test_vector)
        @test result == wanted_tag
    end
    @testset "class application" begin
        test_vector = [0b01000001, 0b00000000]
        wanted_tag = ASN1.ASNTag(0x01, false, Bool[0, 0, 0, 0, 1], 0, UInt8[])
        result = ASN1.parse_tag(test_vector)
        @test result == wanted_tag
    end
    @testset "class Context-specific" begin
        test_vector = [0b10000001, 0b00000000]
        wanted_tag = ASN1.ASNTag(0x02, false, Bool[0, 0, 0, 0, 1], 0, UInt8[])
        result = ASN1.parse_tag(test_vector)
        @test result == wanted_tag
    end
    @testset "class Private" begin
        test_vector = [0b11000001, 0b00000000]
        wanted_tag = ASN1.ASNTag(0x03, false, Bool[0, 0, 0, 0, 1], 0, UInt8[])
        result = ASN1.parse_tag(test_vector)
        @test result == wanted_tag
    end
end

@testset "tag encoding" begin
    @testset "encoding primitive" begin
        test_vector = [0b00000001, 0b00000000]
        wanted_tag = ASN1.ASNTag(0x0, false, Bool[0, 0, 0, 0, 1], 0, UInt8[])
        result = ASN1.parse_tag(test_vector)
        @test result == wanted_tag
    end
    @testset "encoding constructed" begin
        test_vector = [0b00100001, 0b00000000]
        wanted_tag = ASN1.ASNTag(0x0, true, Bool[0, 0, 0, 0, 1], 0, UInt8[])
        result = ASN1.parse_tag(test_vector)
        @test result == wanted_tag
    end
end

@testset "tag number" begin
    @testset "tag number short form" begin
        test_vector = [0b00000001, 0b00000000]
        wanted_tag = ASN1.ASNTag(0x0, false, Bool[0, 0, 0, 0, 1], 0, UInt8[])
        result = ASN1.parse_tag(test_vector)
        @test result == wanted_tag
    end
    @testset "tag number indefinite - 1 link" begin
        test_vector = [0b00011111, 0b00000001, 0b00000000]
        wanted_tag = ASN1.ASNTag(0x0, false, Bool[0, 0, 0, 0, 0, 0, 1], 0, UInt8[])
        result = ASN1.parse_tag(test_vector)
        @test result == wanted_tag
    end
    @testset "tag number indefinite - 2 links" begin
        test_vector = [0b00011111, 0b10000001, 0b00000001, 0b00000000]
        wanted_tag = ASN1.ASNTag(0x0, false, Bool[0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1], 0, UInt8[])
        result = ASN1.parse_tag(test_vector)
        @test result == wanted_tag
    end
end

@testset "content length" begin
    @testset "content length definite short ~ zero length" begin
        test_vector = [0b00000001, 0b00000000]
        wanted_tag = ASN1.ASNTag(0x0, false, Bool[0, 0, 0, 0, 1], 0, UInt8[])
        result = ASN1.parse_tag(test_vector)
        @test result == wanted_tag
    end
    @testset "content length definite short ~ nonzero length 1" begin
        test_vector = [0b00000001, 0b00000001, 0b00000001]
        wanted_tag = ASN1.ASNTag(0x0, false, Bool[0, 0, 0, 0, 1], 1, UInt8[1])
        result = ASN1.parse_tag(test_vector)
        @test result == wanted_tag
    end
    @testset "content length definite short ~ nonzero length 2" begin
        test_vector = [0b00000001, 0b00000010, 0b00000001, 0b00000001]
        wanted_tag = ASN1.ASNTag(0x0, false, Bool[0, 0, 0, 0, 1], 2, UInt8[1, 1])
        result = ASN1.parse_tag(test_vector)
        @test result == wanted_tag
    end
    @testset "content length definite long - 1 octet of length, length zero" begin
        test_vector = [0b00000001, 0b10000001, 0b00000000]
        wanted_tag = ASN1.ASNTag(0x0, false, Bool[0, 0, 0, 0, 1], 0, UInt8[])
        result = ASN1.parse_tag(test_vector)
        @test result == wanted_tag
    end
    @testset "content length definite long - 1 octet of length, nonzero length 1" begin
        test_vector = [0b00000001, 0b10000001, 0b00000001, 0b00000000]
        wanted_tag = ASN1.ASNTag(0x0, false, Bool[0, 0, 0, 0, 1], 1, UInt8[0])
        result = ASN1.parse_tag(test_vector)
        @test result == wanted_tag
    end
    @testset "content length definite long - 1 octet of length, nonzero length 2" begin
        test_vector = [0b00000001, 0b10000001, 0b00000010, 0b00000000, 0b00000000]
        wanted_tag = ASN1.ASNTag(0x0, false, Bool[0, 0, 0, 0, 1], 2, UInt8[0, 0])
        result = ASN1.parse_tag(test_vector)
        @test result == wanted_tag
    end
    @testset "content length definite long - 2 octet of length, length zero" begin
        test_vector = [0b00000001, 0b10000010, 0b00000000, 0b00000000]
        wanted_tag = ASN1.ASNTag(0x0, false, Bool[0, 0, 0, 0, 1], 0, UInt8[])
        result = ASN1.parse_tag(test_vector)
        @test result == wanted_tag
    end
    @testset "content length definite long - 2 octet of length, length 1" begin
        test_vector = [0b00000001, 0b10000010, 0b00000000, 0b00000001, 0b00000000]
        wanted_tag = ASN1.ASNTag(0x0, false, Bool[0, 0, 0, 0, 1], 1, UInt8[0])
        result = ASN1.parse_tag(test_vector)
        @test result == wanted_tag
    end
    @testset "content length definite long - 2 octet of length, length 2" begin
        test_vector = [0b00000001, 0b10000010, 0b00000000, 0b00000010, 0b00000000, 0b00000000]
        wanted_tag = ASN1.ASNTag(0x0, false, Bool[0, 0, 0, 0, 1], 2, UInt8[0, 0])
        result = ASN1.parse_tag(test_vector)
        @test result == wanted_tag
    end
    @testset "content length indefinite - zero length content" begin
        test_vector = [0b00000001, 0b10000000, 0b00000000, 0b00000000]
        wanted_tag = ASN1.ASNTag(0x0, false, Bool[0, 0, 0, 0, 1], 0, UInt8[])
        result = ASN1.parse_tag(test_vector)
        @test result == wanted_tag
    end
    @testset "content length indefinite - nonzero length content" begin
        test_vector = [0b00000001, 0b10000000, 0b00000001, 0b00000001, 0b00000000, 0b00000000]
        wanted_tag = ASN1.ASNTag(0x0, false, Bool[0, 0, 0, 0, 1], 2, UInt8[1, 1])
        result = ASN1.parse_tag(test_vector)
        @test result == wanted_tag
    end
end
