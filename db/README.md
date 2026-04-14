//import csv file to mongodb

mongoimport --db schoolsdb --collection schools --drop --type csv --file db/escolas-informacoes-anuais/Dados_Escolas_InformacoesGerais_Wide.csv --headerline

mongoimport --db schoolsdb --collection apSecVariables --drop --type csv --file db/dados-socioeconomicos-AP/dados_porAP_RMSP.csv --headerline

mongoimport --db schoolsdb --collection brSpRmspSecVariables --drop --type csv --file db/dados-socioeconomicos-AP/dados_resumo_brasil_SP_RMSP.csv --headerline

mongoimport --db schoolsdb --collection weightingAreas --drop --type csv --file db/ap2010_rmsp_cem_r.csv --headerline