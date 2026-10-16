struct Coordinate {
    int x;
    int y;
};

class Piece {
    public:
        virtual Coordinate move(Coordinate coord) = 0;
        virtual ~Piece() = 0;
    };

enum class PieceTypes {
    Pawn,
    Knight,
    Bishop,
    Rook,
    Queen,
    King,
};

enum Side {
    White,
    Black,
};

class Pawn : public Piece {
    public:
    Pawn() {

    };

    Coordinate move(Coordinate coord) override {
        
        
        return coord;
    }

};