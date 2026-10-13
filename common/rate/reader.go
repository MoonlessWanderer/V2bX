package rate

import (
	"time"

	"github.com/juju/ratelimit"
	"github.com/xtls/xray-core/common"
	"github.com/xtls/xray-core/common/buf"
)

// Reader applies the same per-user bucket to data read from the client.
// VLESS hands the dispatcher one link whose reader is the upload.
type Reader struct {
	reader  buf.TimeoutReader
	limiter *ratelimit.Bucket
}

func NewRateLimitReader(reader buf.TimeoutReader, limiter *ratelimit.Bucket) buf.TimeoutReader {
	return &Reader{
		reader:  reader,
		limiter: limiter,
	}
}

func (r *Reader) ReadMultiBuffer() (buf.MultiBuffer, error) {
	mb, err := r.reader.ReadMultiBuffer()
	r.wait(mb)
	return mb, err
}

func (r *Reader) ReadMultiBufferTimeout(duration time.Duration) (buf.MultiBuffer, error) {
	mb, err := r.reader.ReadMultiBufferTimeout(duration)
	r.wait(mb)
	return mb, err
}

func (r *Reader) wait(mb buf.MultiBuffer) {
	if mb.Len() > 0 {
		r.limiter.Wait(int64(mb.Len()))
	}
}

func (r *Reader) Interrupt() {
	common.Interrupt(r.reader)
}

func (r *Reader) Close() error {
	return common.Close(r.reader)
}
