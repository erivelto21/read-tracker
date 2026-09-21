import { clsx } from "clsx";

interface Option<T extends string> {
  value: T;
  label: string;
}

interface SegmentedControlProps<T extends string> {
  options: Option<T>[];
  value: T;
  onChange: (value: T) => void;
  "data-testid"?: string;
}

export function SegmentedControl<T extends string>({
  options,
  value,
  onChange,
  "data-testid": testId,
}: SegmentedControlProps<T>): React.JSX.Element {
  return (
    <div
      data-testid={testId}
      className="inline-flex rounded-lg border border-sky-300 bg-white overflow-hidden"
    >
      {options.map((opt) => (
        <button
          key={opt.value}
          type="button"
          onClick={() => {
            onChange(opt.value);
          }}
          className={clsx(
            "px-3 py-1.5 text-sm font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-inset focus:ring-sky-400",
            value === opt.value
              ? "bg-sky-500 text-white"
              : "text-gray-600 hover:bg-sky-50",
          )}
        >
          {opt.label}
        </button>
      ))}
    </div>
  );
}
