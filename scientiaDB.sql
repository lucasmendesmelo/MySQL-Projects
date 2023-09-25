
## Tabela de Usuários
CREATE TABLE Users (
    ID INT AUTO_INCREMENT PRIMARY KEY,
    Nome VARCHAR(255) NOT NULL,
    Email VARCHAR(255) NOT NULL,
    Senha VARCHAR(255) NOT NULL,
    Cidade VARCHAR(255),
    Pais VARCHAR(255)
);

## Tabela de Categorias
CREATE TABLE Categories (
    ID INT AUTO_INCREMENT PRIMARY KEY,
    NomeCategoria VARCHAR(255) NOT NULL
);

## Tabela de Habilidades
CREATE TABLE Skills (
    ID INT AUTO_INCREMENT PRIMARY KEY,
    NomeHabilidade VARCHAR(255) NOT NULL
);

## Tabela de Anúncios
CREATE TABLE Listings (
    ID INT AUTO_INCREMENT PRIMARY KEY,
    TituloAnuncio VARCHAR(255) NOT NULL,
    Descricao TEXT,
    IDUsuario INT,
    IDCategoria INT,
    FOREIGN KEY (IDUsuario) REFERENCES Users(ID),
    FOREIGN KEY (IDCategoria) REFERENCES Categories(ID)
);

## Tabela de Ofertas
CREATE TABLE Offers (
    ID INT AUTO_INCREMENT PRIMARY KEY,
    IDAnunciante INT,
    IDAnuncio INT,
    Mensagem TEXT,
    StatusOferta ENUM('aceita', 'pendente', 'recusada'),
    FOREIGN KEY (IDAnunciante) REFERENCES Users(ID),
    FOREIGN KEY (IDAnuncio) REFERENCES Listings(ID)
);

## Tabela de Avaliações
CREATE TABLE Ratings (
    ID INT AUTO_INCREMENT PRIMARY KEY,
    IDUsuarioAvaliador INT,
    IDUsuarioAvaliado INT,
    Pontuacao INT CHECK (Pontuacao >= 1 AND Pontuacao <= 5),
    Comentario TEXT,
    FOREIGN KEY (IDUsuarioAvaliador) REFERENCES Users(ID),
    FOREIGN KEY (IDUsuarioAvaliado) REFERENCES Users(ID)
);


## Tabela de Mensagens
CREATE TABLE Messages (
    ID INT AUTO_INCREMENT PRIMARY KEY,
    IDRemetente INT,
    IDDestinatario INT,
    Conteudo TEXT,
    DataHoraEnvio DATETIME,
    FOREIGN KEY (IDRemetente) REFERENCES Users(ID),
    FOREIGN KEY (IDDestinatario) REFERENCES Users(ID)
);

## Tabela de Notificações
CREATE TABLE Notifications (
    ID INT AUTO_INCREMENT PRIMARY KEY,
    IDUsuario INT,
    Conteudo TEXT,
    DataHoraNotificacao DATETIME,
    StatusNotificacao ENUM('lida', 'nao_lida'),
    FOREIGN KEY (IDUsuario) REFERENCES Users(ID)
);

## Tabela de Favoritos
CREATE TABLE Favorites (
    IDUsuario INT,
    IDAnuncioFavorito INT,
    FOREIGN KEY (IDUsuario) REFERENCES Users(ID),
    FOREIGN KEY (IDAnuncioFavorito) REFERENCES Listings(ID)
);

## Tabela de Seguindo
CREATE TABLE Following (
    IDUsuarioSeguidor INT,
    IDUsuarioSeguido INT,
    FOREIGN KEY (IDUsuarioSeguidor) REFERENCES Users(ID),
    FOREIGN KEY (IDUsuarioSeguido) REFERENCES Users(ID)
);


############## VIEWS ##############

## View para listar anúncios em uma categoria específica
CREATE VIEW ListingsInCategory AS
SELECT Listings.ID, Listings.TituloAnuncio, Listings.Descricao, Categories.NomeCategoria
FROM Listings
JOIN Categories ON Listings.IDCategoria = Categories.ID;


## View para listar todas as mensagens entre dois usuários
CREATE VIEW UserMessages AS
SELECT Messages.ID, Messages.Conteudo, Messages.DataHoraEnvio, Users.Nome AS Remetente, Users2.Nome AS Destinatario
FROM Messages
JOIN Users ON Messages.IDRemetente = Users.ID
JOIN Users AS Users2 ON Messages.IDDestinatario = Users2.ID;


## View para listar os anúncios favoritos de um usuário
CREATE VIEW UserFavorites AS
SELECT Users.Nome AS Usuario, Listings.TituloAnuncio, Listings.Descricao
FROM Favorites
JOIN Users ON Favorites.IDUsuario = Users.ID
JOIN Listings ON Favorites.IDAnuncioFavorito = Listings.ID;


## View para calcular a média das pontuações de avaliações recebidas por um usuário
CREATE VIEW UserAverageRating AS
SELECT Users.Nome AS Usuario, AVG(Ratings.Pontuacao) AS MediaPontuacao
FROM Ratings
JOIN Users ON Ratings.IDUsuarioAvaliado = Users.ID
GROUP BY Users.Nome;



######################### TRIGGER #######################

## Trigger para atualizar o número de mensagens não lidas de um usuário
DELIMITER //
CREATE TRIGGER UpdateUnreadMessages
AFTER INSERT ON Messages
FOR EACH ROW
BEGIN
    IF NEW.IDDestinatario <> NEW.IDRemetente THEN
        UPDATE Users
        SET UnreadMessages = UnreadMessages + 1
        WHERE ID = NEW.IDDestinatario;
    END IF;
END;
//
DELIMITER ;


## Trigger para calcular a pontuação média de avaliações recebidas por um usuário
DELIMITER //
CREATE TRIGGER UpdateAverageRating
AFTER INSERT ON Ratings
FOR EACH ROW
BEGIN
    DECLARE totalPontuacao INT;
    DECLARE totalAvaliacoes INT;

    SELECT SUM(Pontuacao) INTO totalPontuacao
    FROM Ratings
    WHERE IDUsuarioAvaliado = NEW.IDUsuarioAvaliado;

    SELECT COUNT(*) INTO totalAvaliacoes
    FROM Ratings
    WHERE IDUsuarioAvaliado = NEW.IDUsuarioAvaliado;

    UPDATE Users
    SET MediaAvaliacoes = totalPontuacao / totalAvaliacoes
    WHERE ID = NEW.IDUsuarioAvaliado;
END;
//
DELIMITER ;

## Trigger para suspender um usuário com avaliações negativas
DELIMITER //
CREATE TRIGGER SuspendUserOnNegativeRatings
AFTER INSERT ON Ratings
FOR EACH ROW
BEGIN
    DECLARE negativeRatingsCount INT;

    SELECT COUNT(*) INTO negativeRatingsCount
    FROM Ratings
    WHERE IDUsuarioAvaliado = NEW.IDUsuarioAvaliado AND Pontuacao <= 2;

    IF negativeRatingsCount >= 3 THEN
        UPDATE Users
        SET ContaSuspensa = 1
        WHERE ID = NEW.IDUsuarioAvaliado;
    END IF;
END;
//
DELIMITER ;

## Trigger para registrar a data e hora de criação de um anúncio
DELIMITER //
CREATE TRIGGER SetListingCreationTimestamp
BEFORE INSERT ON Listings
FOR EACH ROW
BEGIN
    SET NEW.DataHoraCriacao = NOW();
END;
//
DELIMITER ;

ALTER TABLE Listings ADD COLUMN DataHoraCriacao DATETIME;












