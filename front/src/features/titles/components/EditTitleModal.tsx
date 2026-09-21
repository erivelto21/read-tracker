import { useEffect, useState } from "react";
import axios from "axios";
import { clsx } from "clsx";
import type { Title, TitleType } from "@/features/titles/types";
import { useUpdateTitle } from "@/features/titles/hooks/useUpdateTitle";

interface EditTitleModalProps {
  title: Title;
  onClose: () => void;
}

type FieldKey = "chapter" | "page" | "link" | "observation";

interface FieldValues {
  chapter: string;
  page: string;
  link: string;
  observation: string;
}

interface ApiErrorBody {
  error: {
    code: string;
    message: string;
    details?: Array<{ field: string; message: string }>;
  };
}

const FIELD_LABELS: Record<FieldKey, string> = {
  chapter: "Chapter",
  page: "Page",
  link: "Link",
  observation: "Observation",
};

function visibleFields(type: TitleType): FieldKey[] {
  switch (type) {
    case "book":
      return ["chapter", "page", "observation"];
    case "manga":
    case "manhua":
    case "novel":
      return ["chapter", "link", "observation"];
    case "article":
      return ["link", "observation"];
  }
}

export function EditTitleModal({
  title,
  onClose,
}: EditTitleModalProps): React.JSX.Element {
  const [fields, setFields] = useState<FieldValues>({
    chapter: title.chapter !== undefined ? String(title.chapter) : "",
    page: title.page !== undefined ? String(title.page) : "",
    link: title.link ?? "",
    observation: title.observation ?? "",
  });
  const [fieldErrors, setFieldErrors] = useState<
    Partial<Record<FieldKey, string>>
  >({});
  const [topLevelError, setTopLevelError] = useState<string | null>(null);

  const { mutate, isPending } = useUpdateTitle();

  useEffect(() => {
    function handleKeyDown(e: KeyboardEvent) {
      if (e.key === "Escape") onClose();
    }
    document.addEventListener("keydown", handleKeyDown);
    return () => {
      document.removeEventListener("keydown", handleKeyDown);
    };
  }, [onClose]);

  function handleFieldChange(key: FieldKey, value: string) {
    setFields((prev) => ({ ...prev, [key]: value }));
    if (fieldErrors[key]) {
      setFieldErrors((prev) => {
        const next = { ...prev };
        Reflect.deleteProperty(next, key);
        return next;
      });
    }
  }

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault();

    // Client-side validation: for article titles, link is required when updating
    if (title.type === "article" && !fields.link.trim()) {
      setFieldErrors((prev) => ({ ...prev, link: "This field is required" }));
      return;
    }

    const payload: Record<string, unknown> = {};
    if (fields.chapter.trim()) payload.chapter = Number(fields.chapter);
    if (fields.page.trim()) payload.page = Number(fields.page);
    if (fields.link.trim()) payload.link = fields.link.trim();
    if (fields.observation.trim())
      payload.observation = fields.observation.trim();

    setTopLevelError(null);
    setFieldErrors({});

    mutate(
      { id: title.id, payload },
      {
        onSuccess: () => {
          onClose();
        },
        onError: (err) => {
          if (axios.isAxiosError(err)) {
            const data = err.response?.data as ApiErrorBody | undefined;
            const status = err.response?.status;

            if (
              status === 400 &&
              data?.error.details &&
              data.error.details.length > 0
            ) {
              const fe: Partial<Record<FieldKey, string>> = {};
              for (const detail of data.error.details) {
                fe[detail.field.toLowerCase() as FieldKey] = detail.message;
              }
              setFieldErrors(fe);
            } else {
              setTopLevelError(
                "An unexpected error occurred. Please try again.",
              );
            }
          } else {
            setTopLevelError("An unexpected error occurred. Please try again.");
          }
        },
      },
    );
  }

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/40"
      onClick={onClose}
    >
      <div
        role="dialog"
        aria-modal="true"
        className="relative bg-white rounded-2xl border border-gray-200 shadow-xl w-full max-w-md mx-4 p-6"
        onClick={(e) => {
          e.stopPropagation();
        }}
      >
        <button
          type="button"
          onClick={onClose}
          aria-label="Close"
          className="absolute top-4 right-4 text-gray-400 hover:text-gray-600 transition-colors text-lg leading-none"
        >
          ✕
        </button>

        <div className="mb-6">
          <h2 className="text-lg font-semibold text-gray-900">{title.name}</h2>
          <p className="text-sm text-gray-500 capitalize mt-0.5">
            {title.type}
          </p>
        </div>

        {topLevelError && (
          <div className="mb-4 rounded-lg bg-amber-50 border border-amber-200 px-4 py-3 text-sm text-amber-800">
            {topLevelError}
          </div>
        )}

        <form onSubmit={handleSubmit} noValidate>
          <div className="space-y-4">
            {visibleFields(title.type).map((key) => (
              <div key={key}>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  {FIELD_LABELS[key]}
                </label>
                <input
                  type={
                    key === "chapter" || key === "page"
                      ? "number"
                      : key === "link"
                        ? "url"
                        : "text"
                  }
                  value={fields[key]}
                  onChange={(e) => {
                    handleFieldChange(key, e.target.value);
                  }}
                  className={clsx(
                    "w-full rounded-lg border px-3 py-2 text-sm text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-sky-400 transition-colors",
                    fieldErrors[key]
                      ? "border-red-400 bg-red-50"
                      : "border-gray-200 bg-gray-50 focus:bg-white",
                  )}
                />
                {fieldErrors[key] && (
                  <p className="mt-1 text-xs text-red-600">
                    {fieldErrors[key]}
                  </p>
                )}
              </div>
            ))}
          </div>

          <div className="flex justify-end gap-3 mt-6">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2 text-sm font-medium text-gray-600 hover:text-gray-800 transition-colors"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={isPending}
              className={clsx(
                "px-4 py-2 text-sm font-medium rounded-lg transition-colors",
                isPending
                  ? "bg-sky-300 text-white cursor-not-allowed"
                  : "bg-sky-500 text-white hover:bg-sky-600",
              )}
            >
              {isPending ? "Saving…" : "Save"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
