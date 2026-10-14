package dispatcher

import "testing"

func TestChooseNodeOutbound(t *testing.T) {
	cases := []struct {
		route, node string
		want        string
		override    bool
	}{
		{route: "direct", node: "", want: "direct", override: false},
		{route: "direct", node: "wireguard", want: "wireguard", override: true},
		{route: "block", node: "wireguard", want: "block", override: false},
		{route: "", node: "wireguard", want: "wireguard", override: true},
	}
	for _, tc := range cases {
		got, override := chooseNodeOutbound(tc.route, tc.node)
		if got != tc.want || override != tc.override {
			t.Fatalf("route %q node %q: got %q %v, want %q %v", tc.route, tc.node, got, override, tc.want, tc.override)
		}
	}
}
