package rate

import (
	"io"
	"testing"
	"time"

	"github.com/juju/ratelimit"
	"github.com/xtls/xray-core/common/buf"
)

type stubReader struct {
	chunks [][]byte
	err    error
}

func (s *stubReader) ReadMultiBuffer() (buf.MultiBuffer, error) {
	if len(s.chunks) == 0 {
		if s.err != nil {
			return nil, s.err
		}
		return nil, io.EOF
	}
	payload := s.chunks[0]
	s.chunks = s.chunks[1:]
	b := buf.New()
	b.Write(payload)
	return buf.MultiBuffer{b}, nil
}

func (s *stubReader) ReadMultiBufferTimeout(time.Duration) (buf.MultiBuffer, error) {
	return s.ReadMultiBuffer()
}

func TestRateLimitReaderKeepsBytesAndWaits(t *testing.T) {
	payload := make([]byte, 100)
	for i := range payload {
		payload[i] = byte(i)
	}
	stub := &stubReader{chunks: [][]byte{payload, append([]byte(nil), payload...)}}
	bucket := ratelimit.NewBucketWithQuantum(time.Second, 100, 100)
	reader := NewRateLimitReader(stub, bucket)

	start := time.Now()
	first, err := reader.ReadMultiBuffer()
	if err != nil {
		t.Fatal(err)
	}
	if first.Len() != 100 || time.Since(start) > 200*time.Millisecond {
		t.Fatalf("first read len=%d waited %s", first.Len(), time.Since(start))
	}
	buf.ReleaseMulti(first)

	start = time.Now()
	second, err := reader.ReadMultiBuffer()
	elapsed := time.Since(start)
	if err != nil {
		t.Fatal(err)
	}
	if second.Len() != 100 {
		t.Fatalf("second read len=%d", second.Len())
	}
	if elapsed < 700*time.Millisecond {
		t.Fatalf("second read was not limited, waited %s", elapsed)
	}
	buf.ReleaseMulti(second)

	start = time.Now()
	_, err = reader.ReadMultiBuffer()
	if err != io.EOF {
		t.Fatalf("eof err=%v", err)
	}
	if time.Since(start) > 200*time.Millisecond {
		t.Fatal("empty read waited on the limiter")
	}
}
