package cmd

import (
	"fmt"
	"time"

	"github.com/InazumaV/V2bX/common/exec"
	"github.com/spf13/cobra"
)

var (
	startCommand = cobra.Command{
		Use:   "start",
		Short: "Start V2bX service",
		Run:   startHandle,
	}
	stopCommand = cobra.Command{
		Use:   "stop",
		Short: "Stop V2bX service",
		Run:   stopHandle,
	}
	restartCommand = cobra.Command{
		Use:   "restart",
		Short: "Restart V2bX service",
		Run:   restartHandle,
	}
	logCommand = cobra.Command{
		Use:   "log",
		Short: "Output V2bX log",
		Run: func(_ *cobra.Command, _ []string) {
			exec.RunCommandStd("journalctl", "-u", "V2bX.service", "-e", "--no-pager", "-f")
		},
	}
)

func init() {
	command.AddCommand(&startCommand)
	command.AddCommand(&stopCommand)
	command.AddCommand(&restartCommand)
	command.AddCommand(&logCommand)
}

func startHandle(_ *cobra.Command, _ []string) {
	r, err := checkRunning()
	if err != nil {
		fmt.Println(Err("check status error: ", err))
		fmt.Println(Err("V2bX failed to start."))
		return
	}
	if r {
		fmt.Println(Ok("V2bX is already running. Choose restart if you want to restart it."))
	}
	_, err = exec.RunCommandByShell("systemctl start V2bX.service")
	if err != nil {
		fmt.Println(Err("exec start cmd error: ", err))
		fmt.Println(Err("V2bX failed to start."))
		return
	}
	time.Sleep(time.Second * 3)
	r, err = checkRunning()
	if err != nil {
		fmt.Println(Err("check status error: ", err))
		fmt.Println(Err("V2bX failed to start."))
	}
	if !r {
		fmt.Println(Err("V2bX may have failed to start. Please check the logs with V2bX log."))
		return
	}
	fmt.Println(Ok("V2bX started. Use V2bX log to view the logs."))
}

func stopHandle(_ *cobra.Command, _ []string) {
	_, err := exec.RunCommandByShell("systemctl stop V2bX.service")
	if err != nil {
		fmt.Println(Err("exec stop cmd error: ", err))
		fmt.Println(Err("V2bX failed to stop."))
		return
	}
	time.Sleep(2 * time.Second)
	r, err := checkRunning()
	if err != nil {
		fmt.Println(Err("check status error:", err))
		fmt.Println(Err("V2bX failed to stop."))
		return
	}
	if r {
		fmt.Println(Err("V2bX did not stop. It may need more than two seconds. Please check the logs shortly."))
		return
	}
	fmt.Println(Ok("V2bX stopped."))
}

func restartHandle(_ *cobra.Command, _ []string) {
	_, err := exec.RunCommandByShell("systemctl restart V2bX.service")
	if err != nil {
		fmt.Println(Err("exec restart cmd error: ", err))
		fmt.Println(Err("V2bX failed to restart."))
		return
	}
	r, err := checkRunning()
	if err != nil {
		fmt.Println(Err("check status error: ", err))
		fmt.Println(Err("V2bX failed to restart."))
		return
	}
	if !r {
		fmt.Println(Err("V2bX may have failed to start. Please check the logs with V2bX log."))
		return
	}
	fmt.Println(Ok("V2bX restarted."))
}
