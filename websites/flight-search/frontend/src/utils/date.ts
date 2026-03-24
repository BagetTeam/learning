export function toDateString(d: Date): string {
  return d.toISOString().split('T')[0];
}

export function addDays(d: Date, n: number): Date {
  const result = new Date(d);
  result.setDate(result.getDate() + n);
  return result;
}

export function getDefaultDepartureDate(): string {
  return toDateString(addDays(new Date(), 14));
}

export function getDefaultReturnDate(): string {
  return toDateString(addDays(new Date(), 21));
}

export function getMaxBookingDate(): string {
  const d = new Date();
  d.setMonth(d.getMonth() + 12);
  return toDateString(d);
}

export function getDaysInMonth(year: number, month: number): number {
  return new Date(year, month, 0).getDate();
}

export function getFirstDayOfMonth(year: number, month: number): number {
  return new Date(year, month - 1, 1).getDay();
}

export function formatMonthYear(year: number, month: number): string {
  return new Date(year, month - 1).toLocaleDateString('en-US', {
    month: 'long',
    year: 'numeric',
  });
}
