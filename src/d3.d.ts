// D3 v6 type extensions - D3 v6 compatibility declarations
declare module 'd3' {
  // Core exports
  export let currentEvent: any;
  export function append(name: string): any;
  export function select(selector: string | HTMLElement): any;
  export function selectAll(selector: string): any;
  
  // Scales
  export function scaleTime(): any;
  export function scaleLinear(): any;
  export function scaleBand(): any;
  export function scaleOrdinal(range?: any[]): any;
  
  // Generators
  export function line(...args: any[]): any;
  export function arc(): any;
  export function pie(): any;
  export function stack(): any;
  
  // Axes  
  export function axisTop(scale: any): any;
  export function axisRight(scale: any): any;
  export function axisBottom(scale: any): any;
  export function axisLeft(scale: any): any;
  
  // Data functions
  export function max(array: any[], accessor?: (d: any) => number): number;
  export function min(array: any[], accessor?: (d: any) => number): number;
  export function extent(array: any[], accessor?: (d: any) => number): [number, number];
  export function bisector(accessor: (d: any) => any): any;
  
  // Utilities
  export function interpolate(a: any, b: any): any;
  export function timeParse(specifier: string): (dateString: string) => Date;
  export function format(specifier: string): (n: number) => string;
  export function pointer(event: any, node?: Node): [number, number];
  
  // Color schemes
  export const schemeCategory10: string[];
}
