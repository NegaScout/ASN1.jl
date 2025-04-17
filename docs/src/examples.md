# Mock example
```@example
using ASN1
test_vector = [0b00000001, 0b10000010, 0b00000000, 0b00000001, 0b00000000]
println("A mock tag: ", test_vector)
tag = ASN1.deserialize_ber(test_vector)
println("Deserialized form:")
println(tag)
println("Serialized again: ", ASN1.serialize_ber(tag))
```
