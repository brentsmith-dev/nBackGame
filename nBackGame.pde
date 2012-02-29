// pin mappings
const int blueLEDPin = 2;
const int greenLEDPin = 4;
const int redLEDPin = 3;
const int SCORE_PIN_1 = 9;
const int SCORE_PIN_2 = 8;
const int SCORE_PIN_3 = 10;
const int SCORE_PIN_4 = 7;
const int SCORE_PIN_5 = 6;
const int SCORE_PIN_6 = 5;
const int Player1ButtonPin = A3;
const int Player2ButtonPin = A2;

// game settings
const int nbackDelay = 1500;

// play states
const int GAME_STATE_PREP = -1;
const int GAME_STATE_INIT = 0;
const int GAME_STATE_SELECT_LEVEL = 1;
const int GAME_STATE_START = 2;
const int GAME_STATE_ACTIVE= 3;
const int GAME_STATE_OVER = 4;
const int GAME_STATE_RESET = 5;

int gameState = -1;

const int PLAY_STATE_CLEAR = 0;
const int PLAY_STATE_ACTIVE= 1;
const int PLAY_STATE_NEXT = 2;

int playState = 0;

int player1ButtonState = 0;
int player2ButtonState = 0;
int player1PreviousButtonState = 0;
int player2PreviousButtonState = 0;

int level = 0;

boolean player1Clicked = false;
boolean player2Clicked = false;
boolean player1HadClicked = false;
boolean player2HadClicked = false;
boolean player1Accepted = false;
boolean player2Accepted = false;
boolean initalized = false;

int history[7];
int historyIterator = 0;
int historyFull = false;
int score = 0;
boolean hit = false;
long startTime = 0;
int colour = 0;
boolean turnScored = false;
int gameOverCounter = 0;

void setup() {
  Serial.begin(9600);
  pinMode(redLEDPin, OUTPUT);
  pinMode(greenLEDPin, OUTPUT);
  pinMode(blueLEDPin, OUTPUT);
  pinMode(SCORE_PIN_1, OUTPUT);
  pinMode(SCORE_PIN_2, OUTPUT);
  pinMode(SCORE_PIN_3, OUTPUT);
  pinMode(SCORE_PIN_4, OUTPUT);
  pinMode(SCORE_PIN_5, OUTPUT);
  pinMode(SCORE_PIN_6, OUTPUT);
  randomSeed(analogRead(0));
}

void loop(){
  
  switch (gameState) {
    case GAME_STATE_PREP:
      gameOverCounter = 0;
      level = 0;
      score = 0;
      player1Accepted = false;
      player2Accepted = false;
      playState = PLAY_STATE_CLEAR;
      setClear();
      scorePinDemo();
      gameState = GAME_STATE_INIT;
      break;
    // Wait for player one to initialize the game
    case GAME_STATE_INIT:
      if (checkPlayer1Click()){
        setGreen();
        delay(1000);
        setClear();
        gameState = GAME_STATE_SELECT_LEVEL;
      }
      break;
    case GAME_STATE_SELECT_LEVEL:
      if (checkPlayer1Click()){
        level ++;
        lightLevel(level);
        setBlue();
        delay(500);
        setClear();
      }
      if (checkPlayer2Click()){
        setGreen();
        delay(500);
        setClear();
        gameState = GAME_STATE_START;
      }
      break;
    case GAME_STATE_START:
      if (checkPlayer1Click()){
        Serial.println("Player 1 Accepted");
        fillPlayer1();
        player1Accepted = true;
      }
      if (checkPlayer2Click()){
        Serial.println("Player 2 Accepted");
        fillPlayer2();
        player2Accepted = true;
      }
      if (player1Accepted && player2Accepted){
        delay(500);
        clearPlayer1();
        clearPlayer2();
        startupPattern();
        gameState = GAME_STATE_ACTIVE;
      }
      break;
    case GAME_STATE_ACTIVE:
      
      switch(playState){
        
        case PLAY_STATE_CLEAR:
          Serial.println("Game Clear");
          setClear();
          delay(1000);
          playState = PLAY_STATE_NEXT;
          break;
          
        case PLAY_STATE_NEXT:
          Serial.println("Next");
          player1HadClicked = false;
          player2HadClicked = false;
          // update the colour
          colour = random(0,3);
          if (colour == 1){
            setRed();
          }else if (colour == 2){
            setGreen();
          }else{
            setBlue();
          }
          startTime = millis();
          
          // don't bother checking for hits until we've had a sufficient
          // number of colours appear
          if (historyFull){
            // check for player1 nback hit
            hit = (colour == history[historyIterator]);
          }
          history[historyIterator] = colour;
          if (historyIterator == level - 1){
              historyIterator = 0;
              historyFull = true;
          }else{
            historyIterator++;
          }  
          Serial.print(colour);
          Serial.print(" : ");
          if (hit){
            Serial.println("hit");
          }else{
            Serial.println("miss");
          }
          turnScored = false;
          playState = PLAY_STATE_ACTIVE;
          break;
        
        case PLAY_STATE_ACTIVE:
          if (checkPlayer1Click() && !turnScored){
            if (hit){
              score --;
            }else{
              score ++;
            }
            checkScore();
            turnScored = true;
            //playState = PLAY_STATE_CLEAR;
          }
          if (checkPlayer2Click() && !turnScored){
            if (hit){
              score ++;
            }else{
              score --;
            }
            checkScore();
            turnScored = true;
            //playState = PLAY_STATE_CLEAR;
          }
          if (millis() - startTime >= nbackDelay){
            playState = PLAY_STATE_CLEAR;
          }
          break;
      }
      
      break;  
    case GAME_STATE_OVER:
      Serial.println("Game Over");
      gameOverCounter ++;
      if (gameOverCounter > 5){
        gameState = GAME_STATE_PREP;
      }
      setRed();
      delay(200);
      setGreen();
      delay(200);
      setBlue();
      delay(200);
      break;
    default: 
      Serial.println("ERROR IN STATE");
  }
}

//TODO: combine these using and argument
boolean checkPlayer1Click(){
  // read the state of the pushbutton value:
  player1ButtonState = analogRead(Player1ButtonPin);
  //Serial.print("player1ButtonState: ");
  //Serial.println(player1ButtonState);
  player1Clicked = (player1ButtonState > 500 && player1PreviousButtonState < 500);
  player1PreviousButtonState = player1ButtonState;
  return player1Clicked;
}

boolean checkPlayer2Click(){
  // read the state of the pushbutton value:
  player2ButtonState = analogRead(Player2ButtonPin);
  //Serial.print("player2ButtonState: ");
  //Serial.println(player2ButtonState);
  player2Clicked = (player2ButtonState > 500 && player2PreviousButtonState < 500);
  player2PreviousButtonState = player2ButtonState;
  return player2Clicked;
}


void checkScore(){
  Serial.print("Score:");
  Serial.println(score);
  clearPlayer1();
  clearPlayer2();
  if(score == 0){
    //No Lights for even score
  }else if (score == 1){
    digitalWrite(SCORE_PIN_4,HIGH); 
  }else if (score == 2){
    digitalWrite(SCORE_PIN_5,HIGH);
  }else if (score == 3){
    digitalWrite(SCORE_PIN_6,HIGH);
  }else if (score == 4){
    digitalWrite(SCORE_PIN_4,HIGH);
    digitalWrite(SCORE_PIN_5,HIGH);
    digitalWrite(SCORE_PIN_6,HIGH);
    gameOver(); 
  }else if (score == -1){
    digitalWrite(SCORE_PIN_1,HIGH); 
  }else if (score == -2){
    digitalWrite(SCORE_PIN_2,HIGH); 
  }else if (score == -3){
    digitalWrite(SCORE_PIN_3,HIGH);
  }else if (score == -4){
    digitalWrite(SCORE_PIN_1,HIGH);
    digitalWrite(SCORE_PIN_2,HIGH);
    digitalWrite(SCORE_PIN_3,HIGH);
    gameOver();
  }else{
    Serial.println("SCORE ERROR");
  }  
}

void gameOver(){
  Serial.println("Game Over");
  gameState = GAME_STATE_OVER;
}

// This sequence is the countdown to the start of the game.
void startupPattern(){
  setGreen();
  delay(500);
  setClear();
  delay(500);
  setGreen();
  delay(500);
  setClear();
  delay(500);
  setGreen();
  delay(500);
  setClear();
  delay(1000);
}

void lightLevel(int num){
  clearPlayer1();
  if (num == 1){
    digitalWrite(SCORE_PIN_1, HIGH);
  }
  if (num == 2){
    digitalWrite(SCORE_PIN_2, HIGH);
  }
  if (num == 3){
    digitalWrite(SCORE_PIN_1, HIGH);
    digitalWrite(SCORE_PIN_2, HIGH);
  }
  if (num == 4){
    digitalWrite(SCORE_PIN_3, HIGH);
  }
  if (num == 5){
    digitalWrite(SCORE_PIN_1, HIGH);
    digitalWrite(SCORE_PIN_3, HIGH);
  }
  if (num == 6){
    digitalWrite(SCORE_PIN_2, HIGH);
    digitalWrite(SCORE_PIN_3, HIGH);
  }
  if (num == 7){
    digitalWrite(SCORE_PIN_1, HIGH);
    digitalWrite(SCORE_PIN_2, HIGH);
    digitalWrite(SCORE_PIN_3, HIGH);
  }
}


void clearPlayer1(){
  digitalWrite(SCORE_PIN_1, LOW);
  digitalWrite(SCORE_PIN_2, LOW);
  digitalWrite(SCORE_PIN_3, LOW);
}

void clearPlayer2(){
  digitalWrite(SCORE_PIN_4, LOW);
  digitalWrite(SCORE_PIN_5, LOW);
  digitalWrite(SCORE_PIN_6, LOW);
}

void fillPlayer1(){
  digitalWrite(SCORE_PIN_1, HIGH);
  digitalWrite(SCORE_PIN_2, HIGH);
  digitalWrite(SCORE_PIN_3, HIGH);
}

void fillPlayer2(){
  digitalWrite(SCORE_PIN_4, HIGH);
  digitalWrite(SCORE_PIN_5, HIGH);
  digitalWrite(SCORE_PIN_6, HIGH);
}
// set the LED to Off
void setClear(){
  digitalWrite(greenLEDPin, LOW);
  digitalWrite(blueLEDPin, LOW);
  digitalWrite(redLEDPin, LOW);
}

// set the LED to Red
void setRed(){
  digitalWrite(greenLEDPin, LOW);
  digitalWrite(blueLEDPin, LOW);
  digitalWrite(redLEDPin, HIGH);
}

// set the LED to Blue
void setBlue(){
  digitalWrite(redLEDPin, LOW);
  digitalWrite(greenLEDPin, LOW);
  digitalWrite(blueLEDPin, HIGH);  
}

// set the LED to Green
void setGreen(){
  digitalWrite(redLEDPin, LOW);
  digitalWrite(blueLEDPin, LOW);
  digitalWrite(greenLEDPin, HIGH);  
}

void scorePinDemo(){
  int demoDelay = 250;
  digitalWrite(SCORE_PIN_1, LOW);
  digitalWrite(SCORE_PIN_2, LOW);
  digitalWrite(SCORE_PIN_3, LOW);
  digitalWrite(SCORE_PIN_4, LOW);
  digitalWrite(SCORE_PIN_5, LOW);
  digitalWrite(SCORE_PIN_6, LOW);
  digitalWrite(SCORE_PIN_1, HIGH);
  delay(demoDelay);
  digitalWrite(SCORE_PIN_1, LOW);
  digitalWrite(SCORE_PIN_2, HIGH);
  delay(demoDelay);
  digitalWrite(SCORE_PIN_2, LOW);
  digitalWrite(SCORE_PIN_3, HIGH);
  delay(demoDelay);
  digitalWrite(SCORE_PIN_3, LOW);
  digitalWrite(SCORE_PIN_4, HIGH);
  delay(demoDelay);
  digitalWrite(SCORE_PIN_4, LOW);
  digitalWrite(SCORE_PIN_5, HIGH);
  delay(demoDelay);
  digitalWrite(SCORE_PIN_5, LOW);
  digitalWrite(SCORE_PIN_6, HIGH);
  delay(demoDelay);
  digitalWrite(SCORE_PIN_6, LOW);
}
