import { Injectable } from '@angular/core';
import {Http} from '@angular/http';
import 'rxjs/add/operator/map';

@Injectable()
export class WeightingAreaService {

  constructor(private http: Http) { }

  getWeightingArea(codAp) {
    return new Promise((resolve, reject) => {
      this.http.get('/weightingarea/search/' + codAp)
        .map(res => res.json())
        .subscribe(res => {
          resolve(res);
        }, (err) => {
          reject(err);
        });
    });
  }

}
