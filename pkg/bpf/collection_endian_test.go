// SPDX-License-Identifier: Apache-2.0
// Copyright Authors of Cilium

package bpf

import (
	"encoding/binary"
	"testing"
	"unsafe"

	"github.com/cilium/ebpf"
	"github.com/stretchr/testify/require"
)

func loadCollectionSpecNativeEndian(tb testing.TB, path string) *ebpf.CollectionSpec {
	tb.Helper()

	spec, err := ebpf.LoadCollectionSpec(path)
	require.NoError(tb, err)

	normalizeCollectionSpecByteOrder(spec, nativeByteOrder())

	return spec
}

func normalizeCollectionSpecByteOrder(spec *ebpf.CollectionSpec, hostByteOrder binary.ByteOrder) {
	if spec == nil || spec.ByteOrder == nil || spec.ByteOrder == hostByteOrder {
		return
	}

	spec.ByteOrder = hostByteOrder
	for _, prog := range spec.Programs {
		prog.ByteOrder = hostByteOrder
	}
}

func nativeByteOrder() binary.ByteOrder {
	var x uint16 = 0x0102
	if *(*byte)(unsafe.Pointer(&x)) == 0x02 {
		return binary.LittleEndian
	}
	return binary.BigEndian
}

func TestNormalizeCollectionSpecByteOrderMismatched(t *testing.T) {
	spec := &ebpf.CollectionSpec{
		ByteOrder: binary.LittleEndian,
		Programs: map[string]*ebpf.ProgramSpec{
			"prog-a": {ByteOrder: binary.LittleEndian},
			"prog-b": {ByteOrder: binary.BigEndian},
			"prog-c": {},
		},
	}

	normalizeCollectionSpecByteOrder(spec, binary.BigEndian)

	require.Equal(t, binary.BigEndian, spec.ByteOrder)
	require.Equal(t, binary.BigEndian, spec.Programs["prog-a"].ByteOrder)
	require.Equal(t, binary.BigEndian, spec.Programs["prog-b"].ByteOrder)
	require.Equal(t, binary.BigEndian, spec.Programs["prog-c"].ByteOrder)
}

func TestNormalizeCollectionSpecByteOrderNoop(t *testing.T) {
	spec := &ebpf.CollectionSpec{
		Programs: map[string]*ebpf.ProgramSpec{
			"prog-a": {ByteOrder: binary.LittleEndian},
		},
	}

	normalizeCollectionSpecByteOrder(spec, binary.BigEndian)

	require.Nil(t, spec.ByteOrder)
	require.Equal(t, binary.LittleEndian, spec.Programs["prog-a"].ByteOrder)
}

func TestNativeByteOrder(t *testing.T) {
	var expected binary.ByteOrder = binary.BigEndian
	if binary.NativeEndian.Uint16([]byte{0x01, 0x02}) != 0x0102 {
		expected = binary.LittleEndian
	}

	require.Equal(t, expected, nativeByteOrder())
}
