declare module 'leaflet' {
  export interface Map {
    [key: string]: any;
  }
  export interface Layer {
    [key: string]: any;
  }
  export interface LatLng {
    [key: string]: any;
  }
  export interface LatLngBounds {
    [key: string]: any;
  }
  export interface Marker {
    [key: string]: any;
  }
  export interface Circle {
    [key: string]: any;
  }
  export interface Polygon {
    [key: string]: any;
  }
  export interface Polyline {
    [key: string]: any;
  }
  export interface TileLayer {
    [key: string]: any;
  }
  export interface Control {
    [key: string]: any;
  }
  export function map(element: string | HTMLElement, options?: any): Map;
  export function tileLayer(url: string, options?: any): TileLayer;
  export function marker(latlng: any, options?: any): Marker;
  export function latLng(lat: number, lng: number): LatLng;
  export function latLngBounds(corner1: any, corner2: any): LatLngBounds;
  export namespace Control {
    class Zoom {
      constructor(options?: any);
    }
    class Attribution {
      constructor(options?: any);
    }
  }
  export const Icon: any;
  export const icon: any;
}
