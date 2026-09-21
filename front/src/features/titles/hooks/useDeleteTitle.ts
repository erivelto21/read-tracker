import { useMutation, useQueryClient } from "@tanstack/react-query";
import { deleteTitle } from "@/api/titles";
import { queryKeys } from "@/lib/queryKeys";

export function useDeleteTitle() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: string) => deleteTitle(id),
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: queryKeys.titles.all() });
    },
  });
}
