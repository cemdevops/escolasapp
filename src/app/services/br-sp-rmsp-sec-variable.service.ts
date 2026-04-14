import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';

@Injectable()
export class BrSpRmspSecVariableService {

  constructor(private http: HttpClient) { }

  /* GET ALL socioeconomic variables for Brasil, SP, RMSP */
  /* Teste: http://localhost:3002/br-sp-rmsp-secvariable*/
  getBrSpRmspSecInfo() {
    return new Promise((resolve, reject) => {
      this.http.get('/br-sp-rmsp-secvariable')
        .subscribe(res => {
          resolve(res);
        }, (err) => {
          reject(err);
        });
    });
  }

  /* GET the variable informations of a SINGLE VARIABLE BY ID ("_id"). For example: '5ac3aa1461f5122e72625935' */
  /* Teste: http://localhost:3002/br-sp-rmsp-secvariable/5ac3aa1461f5122e72625935*/
  showBrSpRmspSecInfoByID(id) {
    return new Promise((resolve, reject) => {
      this.http.get('/br-sp-rmsp-secvariable/' + id)
        .subscribe(res => {
          resolve(res);
        }, (err) => {
          reject(err);
        });
    });
  }

  /* GET the variable informations of a SINGLE VARIABLE BY NIVEL ("nivel"). For example: 'Estado de SP' */
  /* Teste: http://localhost:3002/br-sp-rmsp-secvariable/search/Estado%20de%20SP*/
  showBrSpRmspSecInfoByNivel(nivel: string) {
    return new Promise((resolve, reject) => {
      this.http.get('/br-sp-rmsp-secvariable/search/' + nivel)
        .subscribe(res => {
          resolve(res);
        }, (err) => {
          reject(err);
        });
    });
  }

  /* Get the data of a Nivel's variable*/
  /* Teste: http://localhost:3002/br-sp-rmsp-secvariable/search/Estado%20de%20SP/ses.ocup*/
  showBrSpRmspSecInfoByNivelAndVariable(nivel: string, variable: string) {
    return new Promise((resolve, reject) => {
      this.http.get('/br-sp-rmsp-secvariable/search/' + nivel + '/' + variable)
        .subscribe(res => {
          resolve(res);
        }, (err) => {
          reject(err);
        });
    });
  }

}
