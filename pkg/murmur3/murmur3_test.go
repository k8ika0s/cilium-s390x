// SPDX-License-Identifier: Apache-2.0
// Copyright Authors of Cilium

package murmur3

import (
	"testing"

	"golang.org/x/sys/cpu"
)

func TestMurmur3(t *testing.T) {
	var tests = []struct {
		seed     uint32
		h1Little uint64
		h2Little uint64
		h1Big    uint64
		h2Big    uint64
		s        string
	}{
		{0, 0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 0x0000000000000000, ""},
		{1234, 0x1629cce705a7069c, 0x316c1fbd953aaecd, 0x1629cce705a7069c, 0x316c1fbd953aaecd, "hello world"},
		{500, 0x188f69f0abbd67de, 0x1b0eeb31b4c00cb6, 0xf2b926b974bb6cd5, 0xba5a559508a8294d, "lorem ipsum dolor sit amet"},
		{31, 0x24b05ffca412286a, 0x7d81ac914b62fe96, 0x4183a5647ce3a11d, 0x66e5b8d5dc2e5133, "this is a test of 31 bytes long"},
		{0xd09, 0x5e0fd714b3169ae6, 0x2f36e811c1535dc7, 0xca12f469c10d1ca5, 0x0c422dc69ba585fd, "The quick brown fox jumps over the lazy dog."},
	}

	for _, tt := range tests {
		t.Run(tt.s, func(t *testing.T) {
			wantH1, wantH2 := tt.h1Little, tt.h2Little
			if cpu.IsBigEndian {
				wantH1, wantH2 = tt.h1Big, tt.h2Big
			}

			h1, h2 := Hash128([]byte(tt.s), tt.seed)
			if want, got := wantH1, h1; want != got {
				t.Errorf("Unexpected h1:\n\twant:\t0x%x,\n\tgot:\t0x%x", want, got)
			}
			if want, got := wantH2, h2; want != got {
				t.Errorf("Unexpected h2:\n\twant:\t0x%x,\n\tgot:\t0x%x", want, got)
			}
		})
	}
}
