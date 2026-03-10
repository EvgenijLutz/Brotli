//
//  BrotliCompressor.cpp
//  Brotli
//
//  Created by Evgenij Lutz on 10.03.26.
//

#include <BrotliEncodeC/BrotliCompressor.hpp>


BrotliCompressor::BrotliCompressor(BrotliEncoderState* fn_nonnull state):
_referenceCounter(1),
_state(state) {
    printf("Hieee\n");
}


BrotliCompressor::~BrotliCompressor() {
    BrotliEncoderDestroyInstance(_state);
    printf("Byeee\n");
}


BrotliCompressor* fn_nonnull BrotliCompressor::create() SWIFT_RETURNS_RETAINED {
    auto instance = BrotliEncoderCreateInstance(nullptr, nullptr, nullptr);
    return new BrotliCompressor(instance);
}


void BrotliCompressor::test() {
    printf("Test\n");
}


FN_IMPLEMENT_SWIFT_INTERFACE1(BrotliCompressor)
