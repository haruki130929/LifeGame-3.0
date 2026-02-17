// File: Bag/BagCoding.swift
import Foundation

func bag_decode<T: Decodable>(_ type: T.Type, from data: Data) -> T? {
    try? JSONDecoder().decode(T.self, from: data)
}

func bag_encode<T: Encodable>(_ value: T) -> Data? {
    try? JSONEncoder().encode(value)
}
