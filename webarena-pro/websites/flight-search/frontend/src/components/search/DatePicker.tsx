interface Props {
  label: string;
  value: string; // YYYY-MM-DD
  onChange: (v: string) => void;
  min?: string; // YYYY-MM-DD
  max?: string; // YYYY-MM-DD
  testId?: string;
}

export default function DatePicker({ label, value, onChange, min, max, testId }: Props) {
  return (
    <div className="relative min-w-[150px]" data-testid={testId}>
      <label className="absolute -top-2 left-3 bg-white px-1 text-xs text-gray-500 z-10">{label}</label>
      <input
        type="date"
        value={value}
        min={min}
        max={max}
        onChange={e => onChange(e.target.value)}
        className="w-full rounded-md border border-gray-300 px-3 py-3 text-sm text-gray-900 hover:border-gray-400 focus:border-[#1a73e8] focus:outline-none cursor-pointer"
        aria-label={label}
        data-testid={testId ? `${testId}-input` : undefined}
      />
    </div>
  );
}
