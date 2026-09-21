import { useMutation, useQueryClient } from "@tanstack/react-query";
import { updateTitle } from "@/api/titles";
import { queryKeys } from "@/lib/queryKeys";
import type { UpdateTitlePayload } from "@/features/titles/types";

export function useUpdateTitle() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({
      id,
      payload,
    }: {
      id: string;
      payload: UpdateTitlePayload;
    }) => updateTitle(id, payload),
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: queryKeys.titles.all() });
    },
  });
}
