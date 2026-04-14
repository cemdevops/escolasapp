// Os serviços são úteis para separar toda a lógica que não está relacionada
// à visão em classes separadas como, por exemplo, o acesso a uma API para
// obter dados para exibição na tela

import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';

@Injectable()
export class SchoolService {

  constructor(private http: HttpClient) { }

  getAllSchools() {
    return new Promise((resolve, reject) => {
      this.http.get('/school')
        .subscribe(res => {
          resolve(res);
        }, (err) => {
          reject(err);
        });
    });
  }

  /* Get a single School by ID ("_id"). For example: '58dd2c8be6f8cc9ae0fcfec4' */
  showEscola(id) {
    return new Promise((resolve, reject) => {
      this.http.get('/school/' + id)
        .subscribe(res => {
          resolve(res);
        }, (err) => {
          reject(err);
        });
    });
  }

}
