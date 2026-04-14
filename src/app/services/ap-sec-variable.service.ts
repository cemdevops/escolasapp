import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';

@Injectable()
export class ApSecVariableService {

  constructor(private http: HttpClient) { }

  getAllWeightingAreasInfo() {
    return new Promise((resolve, reject) => {
      this.http.get('/ap-secvariable')
        .subscribe(res => {
          resolve(res);
        }, (err) => {
          reject(err);
        });
    });
  }

  /* Get a single School by ID ("_id"). For example: '5ac3a91961f5122e72625650' */
  showWeightingAreaInfoByID(id) {
    return new Promise((resolve, reject) => {
      this.http.get('/ap-secvariable/' + id)
        .subscribe(res => {
          resolve(res);
        }, (err) => {
          reject(err);
        });
    });
  }

  /* GET the variable informations of a SINGLE AP  BY codap ("codap"). For example: '3503901003001' */
  showWeightingAreaInfoByCodAP(codAP: string) {
    return new Promise((resolve, reject) => {
      this.http.get('/ap-secvariable/search/' + codAP)
        .subscribe(res => {
          resolve(res);
        }, (err) => {
          reject(err);
        });
    });
  }

}
