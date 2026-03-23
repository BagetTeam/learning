import { useEffect, useRef, useState } from 'react';
import { searchAirports } from '../../api/client';
import type { AutocompleteResult } from '../../api/types';
import { useDebounce } from '../../hooks/useDebounce';

interface Props {
  label: string;
  value: string;          // IATA code
  displayValue: string;   // "New York (JFK)"
  onChange: (iata: string, display: string) => void;
  placeholder?: string;
  testId?: string;
}

export default function AirportInput({ label, value, displayValue, onChange, placeholder, testId }: Props) {
  const [query, setQuery] = useState(displayValue);
  const [results, setResults] = useState<AutocompleteResult[]>([]);
  const [open, setOpen] = useState(false);
  const [focused, setFocused] = useState(false);
  const debouncedQuery = useDebounce(query, 200);
  const wrapperRef = useRef<HTMLDivElement>(null);

  // Sync display value when parent changes it
  useEffect(() => {
    if (!focused) setQuery(displayValue);
  }, [displayValue, focused]);

  // Fetch autocomplete results
  useEffect(() => {
    if (!focused) return;
    if (debouncedQuery.length < 1) {
      setResults([]);
      return;
    }
    let cancelled = false;
    searchAirports(debouncedQuery).then(r => {
      if (!cancelled) {
        setResults(r);
        setOpen(r.length > 0);
      }
    });
    return () => { cancelled = true; };
  }, [debouncedQuery, focused]);

  // Close on click outside
  useEffect(() => {
    function handler(e: MouseEvent) {
      if (wrapperRef.current && !wrapperRef.current.contains(e.target as Node)) {
        setOpen(false);
        setFocused(false);
        if (!value) setQuery('');
      }
    }
    document.addEventListener('mousedown', handler);
    return () => document.removeEventListener('mousedown', handler);
  }, [value]);

  function select(r: AutocompleteResult) {
    onChange(r.iata, `${r.city_name} (${r.iata})`);
    setQuery(`${r.city_name} (${r.iata})`);
    setOpen(false);
    setFocused(false);
  }

  return (
    <div ref={wrapperRef} className="relative flex-1 min-w-[180px]" data-testid={testId}>
      <label className="absolute -top-2 left-3 bg-white px-1 text-xs text-gray-500 z-10">{label}</label>
      <input
        type="text"
        value={query}
        onChange={e => { setQuery(e.target.value); setOpen(true); }}
        onFocus={() => { setFocused(true); setQuery(''); setOpen(true); }}
        placeholder={placeholder || 'City or airport'}
        className="w-full rounded-md border border-gray-300 px-3 py-3 text-sm text-gray-900 placeholder-gray-400 hover:border-gray-400 focus:border-[#1a73e8] focus:outline-none"
        aria-label={label}
        data-testid={testId ? `${testId}-input` : undefined}
        autoComplete="off"
      />
      {open && results.length > 0 && (
        <ul
          className="absolute top-full left-0 right-0 z-50 mt-1 max-h-64 overflow-y-auto rounded-lg border border-gray-200 bg-white shadow-lg"
          data-testid={testId ? `${testId}-dropdown` : undefined}
          role="listbox"
        >
          {results.map(r => (
            <li
              key={r.iata}
              onClick={() => select(r)}
              className="flex cursor-pointer items-center gap-3 px-4 py-3 hover:bg-gray-50"
              role="option"
              data-testid={`airport-option-${r.iata}`}
              aria-selected={r.iata === value}
            >
              <svg className="h-5 w-5 flex-shrink-0 text-gray-400" viewBox="0 0 24 24" fill="none">
                <path d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5c-1.38 0-2.5-1.12-2.5-2.5s1.12-2.5 2.5-2.5 2.5 1.12 2.5 2.5-1.12 2.5-2.5 2.5z" fill="currentColor"/>
              </svg>
              <div className="flex-1 min-w-0">
                <div className="text-sm font-medium text-gray-900 truncate">{r.city_name} ({r.iata})</div>
                <div className="text-xs text-gray-500 truncate">{r.name}, {r.country}</div>
              </div>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
