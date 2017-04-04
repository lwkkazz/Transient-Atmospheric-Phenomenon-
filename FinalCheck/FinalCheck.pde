import javax.swing.*;
import processing.video.*;

PImage  img, last;
Movie   vid;

ArrayList<Integer> pointsX, pointsY;

color pixelColor;
color TARGET_COLOR  = color(216, 142, 16);
int closest, closestLoc, threshold = 1000, xP=0, yP=0;

boolean type; 

void setup(){
  surface.setVisible(false);
  closest = 512;
  closestLoc =  -1; 
  
  pointsX = new ArrayList();
  pointsY = new ArrayList();
  
  Object[] options = {"Imagem","Video"};
  
  int answer = JOptionPane.showOptionDialog(null, "Escolha o tipo de arquivo", "Final Check", JOptionPane.YES_NO_OPTION, JOptionPane.QUESTION_MESSAGE,null, options, options[0]); 

  if(answer==0){
    type = false;
    selectInput("Escolha uma imagem para análise", "selectImage");
    if(img!=null)
        surface.setSize(img.height, img.width);

   }else if(answer==1){
    type = true;
    surface.setSize(1280, 720);
    last = createImage(1280,720, RGB);
    selectInput("Escolha um vídeo para análise", "selectVideo");
   }else{
    JOptionPane.showMessageDialog(null, "Não foi possivel identificar a escolha", "Final Check", JOptionPane.ERROR_MESSAGE);
    exit();
    }
}


void selectVideo(File selection) {
  if (selection == null) {
    setup();
  } else {
    if(isVideo(selection.getAbsolutePath())){
      try{
        vid = new Movie(this, selection.getAbsolutePath());
        vid.loop();
        surface.setVisible(true);
      }catch(Exception e){
        JOptionPane.showMessageDialog(null, "Não foi possivel abrir o arquivo selecionado", "Final Check", JOptionPane.ERROR_MESSAGE);
        setup();
      }
      
    }else{
        JOptionPane.showMessageDialog(null, "O arquivo selecionado não era um video", "Final Check", JOptionPane.WARNING_MESSAGE);
        setup();
    }
  }
}

void selectImage(File selection) {
  if (selection == null) {
    setup();
  }else{
    if(isImage(selection.getAbsolutePath())){
        try{
        img = loadImage(selection.getAbsolutePath());
        surface.setVisible(true);
        }catch(Exception e){
          setup();
        }
        if(img.height > displayHeight/2)
                img.resize((int) 3f*(img.height/4), 0);
      
        if(img.width > displayWidth/2)
                img.resize(0, (int) 3f*(img.width/4));
        
        surface.setSize(img.width, img.height);
        background(0);
    }else{
        JOptionPane.showMessageDialog(null, "O arquivo selecionado não era uma imagem", "Final Check", JOptionPane.WARNING_MESSAGE);
        setup();
    }
  }
}

boolean isImage(String test){
 return (
   test.endsWith(".jpg")  ||
   test.endsWith(".jpeg") ||
   test.endsWith(".png"));
}

boolean isVideo(String test){
 return (
   test.endsWith(".mp4") ||
   test.endsWith(".mov") ||
   test.endsWith(".wmv"));
}


void draw(){
  if(!type){
    drawImage();
  }else{
    drawVideo();
  }
   textSize(32);
   fill(255,255,51);
   text("X: "+xP+"|Y: "+yP, 10, 30);
}

void drawImage(){
  if(img != null){
    loadPixels(); 
    img.loadPixels();
    if(pixels.length==img.pixels.length){    
      for (int y = 0; y < img.height; y++ ) {
        for (int x = 0; x < img.width; x++ ) {
            int loc = x + y*img.width;      
            
            pixels[loc] = color(red(img.pixels [loc]), green(img.pixels [loc]), blue(img.pixels [loc]));
            
            int temp = distToTarget(img.pixels[loc]);
            if(temp < closest){
              pointsX.add(x);
              pointsY.add(y);
             closestLoc = loc;
            }
        }
      }
      if(calcMed(pointsX)!=0)
       xP = calcMed(pointsX);
    
      if(calcMed(pointsY)!=0)
       yP = calcMed(pointsY);
      
      img.updatePixels();
      updatePixels();
      fill(color(0,0,255));
      ellipse(xP, yP, (img.height/100), (img.height/100));
    }
  }
}

void drawVideo(){
  if(vid != null){
    
      vid.loadPixels();
      last.loadPixels();
      loadPixels();
      
      image(vid, 0, 0);

      for (int y = 0; y < vid.height; y++ ) {
        for (int x = 0; x < vid.width; x++ ) {
          int loc = x + y*vid.width;     
          
          color colorNow = vid.pixels[loc];
          color colorLast = last.pixels[loc];
          
          int temp = distToFrom(colorLast, colorNow);
          
          if (temp>threshold){
            if(distToTarget(colorNow)<threshold){
              pixels[loc] = vid.pixels[loc]; 
              pointsX.add(x);
              pointsY.add(y);
            }else
             pixels[loc] = vid.pixels[loc]; 
          }else{
             pixels[loc] = vid.pixels[loc]; 
          }
        }
      }
      
      if(calcMed(pointsX)!=0)
        xP = calcMed(pointsX);
    
      if(calcMed(pointsY)!=0)
        yP = calcMed(pointsY);
      
      updatePixels();
      
      textSize(32);
      fill(255,255,51);
      text("X: "+xP+"|Y: "+yP, 10, 30);
      
      fill(color(0,0,255));
      ellipse(xP, yP, (vid.height/100), (vid.height/100));
      
         
      pointsX = new ArrayList();
      pointsY = new ArrayList();
    } 
}



int calcMed(ArrayList points){
   int total = points.size(); 
   int sum  = 0;
   
   for(int i = 0; i < points.size(); i++)
    sum += (int) points.get(i);
    
   if(total!=0)
     return sum/total;
   else
     return 0;
}

void movieEvent(Movie m) {
  last.copy(vid, 0, 0, vid.width, vid.height, 0, 0, last.width, last.height);
  last.updatePixels();
  m.read();
}


int distToFrom(color nextColor, color lastColor){
  int dist;  
  float x1, x2, y1, y2, z1, z2;
  
  x1 = red(nextColor);
  y1 = green(nextColor);
  z1 = blue(nextColor);
  
  x2 = red(lastColor);
  y2 = green(lastColor);
  z2 = blue(lastColor);
  
  dist = (int) ((Math.pow(x2-x1,2))+(Math.pow(y2-y1,2)+(Math.pow(z2-z1,2))));
  return dist;
}


int distToTarget(color nextColor){
  int dist;  
  float x1, x2, y1, y2, z1, z2;
  
  x1 = red(nextColor);
  y1 = green(nextColor);
  z1 = blue(nextColor);
  
  x2 = red(TARGET_COLOR);
  y2 = green(TARGET_COLOR);
  z2 = blue(TARGET_COLOR);
  
  dist = (int) ((Math.pow(x2-x1,2))+(Math.pow(y2-y1,2)+(Math.pow(z2-z1,2))));
  return dist;
}