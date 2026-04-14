import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';

@Injectable()
export class WeightingAreaService {

  constructor(private http: HttpClient) { }

  getWeightingArea(codAp) {
    return new Promise((resolve, reject) => {
      this.http.get('/weightingarea/search/' + codAp)
        .subscribe(res => {
          resolve(res);
        }, (err) => {
          reject(err);
        });
    });
  }

}
