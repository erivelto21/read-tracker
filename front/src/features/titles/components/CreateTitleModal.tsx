import { useEffect, useState } from "react";
import axios from "axios";
import { clsx } from "clsx";
import { SegmentedControl } from "@/components/SegmentedControl";
import { TITLE_TYPES } from "@/features/titles/types";
import type { CreateTitlePayload, TitleType } from "@/features/titles/types";
import { useCreateTitle } from "@/features/titles/hooks/useCreateTitle";

interface CreateTitleModalProps {
  onClose: () => void;
}

const TYPE_OPTIONS = TITLE_TYPES.map((t) => ({
  value: t,
  label: t.charAt(0).toUpperCase() + t.slice(1),
}));

type FieldKey = "name" | "chapter" | "page" | "link" | "observation";

interface FieldValues {
  name: string;
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

const EMPTY_FIELDS: FieldValues = {
  name: "",
  chapter: "",
  page: "",
  link: "",
  observation: "",
};

const FIELD_LABELS: Record<FieldKey, string> = {
  name: "Name",
  chapter: "Chapter",
  page: "Page",
  link: "Link",
  observation: "Observation",
};

function visibleFields(type: TitleType): FieldKey[] {
  switch (type) {
    case "book":
      return ["name", "chapter", "page", "observation"];
    case "manga":
    case "manhua":
    case "novel":
      return ["name", "chapter", "link", "observation"];
    case "article":
      return ["name", "link", "observation"];
  }
}

function requiredFields(type: TitleType): FieldKey[] {
  switch (type) {
    case "book":
      return ["name", "chapter", "page"];
    case "manga":
    case "manhua":
    case "novel":
      return ["name", "chapter", "link"];
    case "article":
      return ["name", "link"];
  }
}

export function CreateTitleModal({
  onClose,
}: CreateTitleModalProps): React.JSX.Element {
  const [step, setStep] = useState<1 | 2>(1);
  const [selectedType, setSelectedType] = useState<TitleType | "">("");
  const [fields, setFields] = useState<FieldValues>(EMPTY_FIELDS);
  const [fieldErrors, setFieldErrors] = useState<
    Partial<Record<FieldKey, string>>
  >({});
  const [topLevelError, setTopLevelError] = useState<string | null>(null);

  const { mutate, isPending } = useCreateTitle();

  // Task 3.1 — Escape key handler
  useEffect(() => {
    function handleKeyDown(e: KeyboardEvent) {
      if (e.key === "Escape") onClose();
    }
    document.addEventListener("keydown", handleKeyDown);
    return () => {
      document.removeEventListener("keydown", handleKeyDown);
    };
  }, [onClose]);

  // Task 3.8 — clear field error on change
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

  function handleNext() {
    if (selectedType) setStep(2);
  }

  function handleBack() {
    setStep(1);
    setFieldErrors({});
    setTopLevelError(null);
  }

  // Task 3.4 — client-side required validation + submit
  function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!selectedType) return;

    const required = requiredFields(selectedType);
    const errors: Partial<Record<FieldKey, string>> = {};
    for (const key of required) {
      if (!fields[key].trim()) {
        errors[key] = "This field is required";
      }
    }
    if (Object.keys(errors).length > 0) {
      setFieldErrors(errors);
      return;
    }

    const payload: CreateTitlePayload = {
      name: fields.name.trim(),
      type: selectedType,
      ...(fields.chapter.trim() ? { chapter: Number(fields.chapter) } : {}),
      ...(fields.page.trim() ? { page: Number(fields.page) } : {}),
      ...(fields.link.trim() ? { link: fields.link.trim() } : {}),
      ...(fields.observation.trim()
        ? { observation: fields.observation.trim() }
        : {}),
    };

    setTopLevelError(null);
    setFieldErrors({});

    mutate(payload, {
      onSuccess: () => {
        onClose();
      },
      // Tasks 3.5 & 3.6 — map server errors
      onError: (err) => {
        if (axios.isAxiosError(err)) {
          const data = err.response?.data as ApiErrorBody | undefined;
          const status = err.response?.status;

          if (status === 409) {
            setTopLevelError(
              data?.error.message ?? "A title with this name already exists.",
            );
          } else if (data?.error.details && data.error.details.length > 0) {
            const fe: Partial<Record<FieldKey, string>> = {};
            for (const detail of data.error.details) {
              fe[detail.field.toLowerCase() as FieldKey] = detail.message;
            }
            setFieldErrors(fe);
          } else {
            setTopLevelError("An unexpected error occurred. Please try again.");
          }
        } else {
          setTopLevelError("An unexpected error occurred. Please try again.");
        }
      },
    });
  }

  return (
    // Task 3.1 — backdrop
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

        {/* Task 3.2 — Step 1: type selector */}
        {step === 1 && (
          <>
            <h2 className="text-lg font-semibold text-gray-900 mb-1">
              Add a new title
            </h2>
            <p className="text-sm text-gray-500 mb-6">What are you reading?</p>

            <SegmentedControl<TitleType>
              options={TYPE_OPTIONS}
              value={selectedType as TitleType}
              onChange={(t) => {
                setSelectedType(t);
              }}
            />

            <div className="flex justify-end gap-3 mt-8">
              <button
                type="button"
                onClick={onClose}
                className="px-4 py-2 text-sm font-medium text-gray-600 hover:text-gray-800 transition-colors"
              >
                Cancel
              </button>
              <button
                type="button"
                onClick={handleNext}
                disabled={!selectedType}
                className={clsx(
                  "px-4 py-2 text-sm font-medium rounded-lg transition-colors",
                  selectedType
                    ? "bg-sky-500 text-white hover:bg-sky-600"
                    : "bg-gray-100 text-gray-400 cursor-not-allowed",
                )}
              >
                Next →
              </button>
            </div>
          </>
        )}

        {/* Tasks 3.3, 3.5, 3.6, 3.7 — Step 2: fields */}
        {step === 2 && selectedType && (
          <form onSubmit={handleSubmit} noValidate>
            <div className="flex items-center gap-2 mb-6">
              <button
                type="button"
                onClick={handleBack}
                className="text-sky-500 hover:text-sky-700 text-sm font-medium transition-colors"
              >
                ←
              </button>
              <h2 className="text-lg font-semibold text-gray-900 capitalize">
                {selectedType}
              </h2>
            </div>

            {/* Task 3.6 — top-level error banner */}
            {topLevelError && (
              <div className="mb-4 rounded-lg bg-amber-50 border border-amber-200 px-4 py-3 text-sm text-amber-800">
                {topLevelError}
              </div>
            )}

            {/* Task 3.3 — conditional fields */}
            <div className="space-y-4">
              {visibleFields(selectedType).map((key) => (
                <div key={key}>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    {FIELD_LABELS[key]}
                    {requiredFields(selectedType).includes(key) && (
                      <span className="text-red-500 ml-1">*</span>
                    )}
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
                    autoFocus={key === "name"}
                    className={clsx(
                      "w-full rounded-lg border px-3 py-2 text-sm text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-sky-400 transition-colors",
                      fieldErrors[key]
                        ? "border-red-400 bg-red-50"
                        : "border-gray-200 bg-gray-50 focus:bg-white",
                    )}
                  />
                  {/* Task 3.5 — inline field error */}
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
                onClick={handleBack}
                className="px-4 py-2 text-sm font-medium text-gray-600 hover:text-gray-800 transition-colors"
              >
                ← Back
              </button>
              {/* Task 3.7 — loading/disabled state */}
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
                {isPending ? "Adding…" : "Add title"}
              </button>
            </div>
          </form>
        )}
      </div>
    </div>
  );
}
