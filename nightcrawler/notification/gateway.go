package notification

import "fmt"

type Gateway struct {
}

func (g Gateway) Notify(sourceName string, chapter float64) {
	fmt.Printf("%s -> %v\n", sourceName, chapter)
}
