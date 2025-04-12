@testset "tag class" begin
    @testset "class universal" begin
        test_vector = [0b00000001, 0b00000000]
        wanted_tag = ASN1.ASNTag(0x0, false, 0, UInt64(0b00001), 1, false, 0, UInt8[], [])
        @test ASN1.serialized_length(wanted_tag) == length(test_vector)
        result = @inferred Union{ASN1.ASNTag, Nothing} ASN1.parse_tag(test_vector)
        @test result == wanted_tag
    end
    @testset "class application" begin
        test_vector = [0b01000001, 0b00000000]
        wanted_tag = ASN1.ASNTag(0x01, false, 0, UInt64(0b00001), 1, false, 0, UInt8[], [])
        @test ASN1.serialized_length(wanted_tag) == length(test_vector)
        result = @inferred Union{ASN1.ASNTag, Nothing} ASN1.parse_tag(test_vector)
        @test result == wanted_tag
    end
    @testset "class Context-specific" begin
        test_vector = [0b10000001, 0b00000000]
        wanted_tag = ASN1.ASNTag(0x02, false, 0, UInt64(0b00001), 1, false, 0, UInt8[], [])
        @test ASN1.serialized_length(wanted_tag) == length(test_vector)
        result = @inferred Union{ASN1.ASNTag, Nothing} ASN1.parse_tag(test_vector)
        @test result == wanted_tag
    end
    @testset "class Private" begin
        test_vector = [0b11000001, 0b00000000]
        wanted_tag = ASN1.ASNTag(0x03, false, 0, UInt64(0b00001), 1, false, 0, UInt8[], [])
        @test ASN1.serialized_length(wanted_tag) == length(test_vector)
        result = @inferred Union{ASN1.ASNTag, Nothing} ASN1.parse_tag(test_vector)
        @test result == wanted_tag
    end
end

@testset "tag encoding" begin
    @testset "encoding primitive" begin
        test_vector = [0b00000001, 0b00000000]
        wanted_tag = ASN1.ASNTag(0x0, false, 0, UInt64(0b00001), 1, false, 0, UInt8[], [])
        @test ASN1.serialized_length(wanted_tag) == length(test_vector)
        result = @inferred Union{ASN1.ASNTag, Nothing} ASN1.parse_tag(test_vector)
        @test result == wanted_tag
    end
    @testset "encoding constructed" begin
        test_vector = [0b00100001, 0b00000000]
        wanted_tag = ASN1.ASNTag(0x0, true, 0, UInt64(0b00001), 1, false, 0, UInt8[], [])
        @test ASN1.serialized_length(wanted_tag) == length(test_vector)
        result = @inferred Union{ASN1.ASNTag, Nothing} ASN1.parse_tag(test_vector)
        @test result == wanted_tag
    end
end

@testset "tag number" begin
    @testset "tag number short form" begin
        test_vector = [0b00000001, 0b00000000]
        wanted_tag = ASN1.ASNTag(0x0, false, 0, UInt64(0b00001), 1, false, 0, UInt8[], [])
        @test ASN1.serialized_length(wanted_tag) == length(test_vector)
        result = @inferred Union{ASN1.ASNTag, Nothing} ASN1.parse_tag(test_vector)
        @test result == wanted_tag
    end
    @testset "tag number long - 1 link" begin
        test_vector = [0b00011111, 0b00000001, 0b00000000]
        wanted_tag = ASN1.ASNTag(0x0, false, 1, UInt64(0b0000001), 1, false, 0, UInt8[], [])
        @test ASN1.serialized_length(wanted_tag) == length(test_vector)
        result = @inferred Union{ASN1.ASNTag, Nothing} ASN1.parse_tag(test_vector)
        @test result == wanted_tag
    end
    @testset "tag number long - 2 links" begin
        test_vector = [0b00011111, 0b10000001, 0b00000001, 0b00000000]
        wanted_tag = ASN1.ASNTag(0x0, false, 2, UInt64(0b00000010000001), 1, false, 0, UInt8[], [])
        @test ASN1.serialized_length(wanted_tag) == length(test_vector)
        result = @inferred Union{ASN1.ASNTag, Nothing} ASN1.parse_tag(test_vector)
        @test result == wanted_tag
    end
end

@testset "content length" begin
    @testset "content length definite short ~ zero length" begin
        test_vector = [0b00000001, 0b00000000]
        wanted_tag = ASN1.ASNTag(0x0, false, 0, UInt64(0b00001), 1, false, 0, UInt8[], [])
        @test ASN1.serialized_length(wanted_tag) == length(test_vector)
        result = @inferred Union{ASN1.ASNTag, Nothing} ASN1.parse_tag(test_vector)
        @test result == wanted_tag
    end
    @testset "content length definite short ~ nonzero length 1" begin
        test_vector = [0b00000001, 0b00000001, 0b00000001]
        wanted_tag = ASN1.ASNTag(0x0, false, 0, UInt64(0b00001), 1, false, 1, UInt8[1], [])
        @test ASN1.serialized_length(wanted_tag) == length(test_vector)
        result = @inferred Union{ASN1.ASNTag, Nothing} ASN1.parse_tag(test_vector)
        @test result == wanted_tag
    end
    @testset "content length definite short ~ nonzero length 2" begin
        test_vector = [0b00000001, 0b00000010, 0b00000001, 0b00000001]
        wanted_tag = ASN1.ASNTag(0x0, false, 0, UInt64(0b00001), 1, false, 2, UInt8[1, 1], [])
        @test ASN1.serialized_length(wanted_tag) == length(test_vector)
        result = @inferred Union{ASN1.ASNTag, Nothing} ASN1.parse_tag(test_vector)
        @test result == wanted_tag
    end
    @testset "content length definite long - 1 octet of length, length zero" begin
        test_vector = [0b00000001, 0b10000001, 0b00000000]
        wanted_tag = ASN1.ASNTag(0x0, false, 0, UInt64(0b00001), 2, false, 0, UInt8[], [])
        @test ASN1.serialized_length(wanted_tag) == length(test_vector)
        result = @inferred Union{ASN1.ASNTag, Nothing} ASN1.parse_tag(test_vector)
        @test result == wanted_tag
    end
    @testset "content length definite long - 1 octet of length, nonzero length 1" begin
        test_vector = [0b00000001, 0b10000001, 0b00000001, 0b00000000]
        wanted_tag = ASN1.ASNTag(0x0, false, 0, UInt64(0b00001), 2, false, 1, UInt8[0], [])
        @test ASN1.serialized_length(wanted_tag) == length(test_vector)
        result = @inferred Union{ASN1.ASNTag, Nothing} ASN1.parse_tag(test_vector)
        @test result == wanted_tag
    end
    @testset "content length definite long - 1 octet of length, nonzero length 2" begin
        test_vector = [0b00000001, 0b10000001, 0b00000010, 0b00000000, 0b00000000]
        wanted_tag = ASN1.ASNTag(0x0, false, 0, UInt64(0b00001), 2, false, 2, UInt8[0, 0], [])
        @test ASN1.serialized_length(wanted_tag) == length(test_vector)
        result = @inferred Union{ASN1.ASNTag, Nothing} ASN1.parse_tag(test_vector)
        @test result == wanted_tag
    end
    @testset "content length definite long - 2 octet of length, length zero" begin
        test_vector = [0b00000001, 0b10000010, 0b00000000, 0b00000000]
        wanted_tag = ASN1.ASNTag(0x0, false, 0, UInt64(0b00001), 3, false, 0, UInt8[], [])
        @test ASN1.serialized_length(wanted_tag) == length(test_vector)
        result = @inferred Union{ASN1.ASNTag, Nothing} ASN1.parse_tag(test_vector)
        @test result == wanted_tag
    end
    @testset "content length definite long - 2 octet of length, length 1" begin
        test_vector = [0b00000001, 0b10000010, 0b00000000, 0b00000001, 0b00000000]
        wanted_tag = ASN1.ASNTag(0x0, false, 0, UInt64(0b00001), 3, false, 1, UInt8[0], [])
        @test ASN1.serialized_length(wanted_tag) == length(test_vector)
        result = @inferred Union{ASN1.ASNTag, Nothing} ASN1.parse_tag(test_vector)
        @test result == wanted_tag
    end
    @testset "content length definite long - 2 octet of length, length 2" begin
        test_vector = [0b00000001, 0b10000010, 0b00000000, 0b00000010, 0b00000000, 0b00000000]
        wanted_tag = ASN1.ASNTag(0x0, false, 0, UInt64(0b00001), 3, false, 2, UInt8[0, 0], [])
        @test ASN1.serialized_length(wanted_tag) == length(test_vector)
        result = @inferred Union{ASN1.ASNTag, Nothing} ASN1.parse_tag(test_vector)
        @test result == wanted_tag
    end
    @testset "content length indefinite - zero length content" begin
        test_vector = [0b00000001, 0b10000000, 0b00000000, 0b00000000]
        wanted_tag = ASN1.ASNTag(0x0, false, 0, UInt64(0b00001), 1, true, 0, UInt8[], [])
        @test ASN1.serialized_length(wanted_tag) == length(test_vector)
        result = @inferred Union{ASN1.ASNTag, Nothing} ASN1.parse_tag(test_vector)
        @test result == wanted_tag
    end
    @testset "content length indefinite - nonzero length content" begin
        test_vector = [0b00000001, 0b10000000, 0b00000001, 0b00000001, 0b00000000, 0b00000000]
        wanted_tag = ASN1.ASNTag(0x0, false, 0, UInt64(0b00001), 1, true, 2, UInt8[1, 1], [])
        @test ASN1.serialized_length(wanted_tag) == length(test_vector)
        result = @inferred Union{ASN1.ASNTag, Nothing} ASN1.parse_tag(test_vector)
        @test result == wanted_tag
    end
end
