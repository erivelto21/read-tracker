import { useMutation, useQueryClient } from "@tanstack/react-query";
import { createTitle } from "@/api/titles";
import { queryKeys } from "@/lib/queryKeys";

export function useCreateTitle() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: createTitle,
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: queryKeys.titles.all() });
    },
  });
}
