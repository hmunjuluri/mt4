
#define MAGIC  20181109
int MaxSlippage=3;

double digits = 10000.0;
input int TargetPips = 50;
input int ZonePips = 20;

double NextLongPositionSize = 0; 
double NextShortPositionSize = 0;

int Direction = -1;
double SourceUp = 0;
double SourceDown = 0;
double TargetUp = 0;
double TargetDown = 0;

double Factor = 1;
input double LotSize = 1;
int CurrentTradeDirection = -1;

int OnInit()
{
   Factor = (TargetPips + ZonePips) / (double)TargetPips;
   
   if(OrdersTotal() > 0)
   {
      readEnv();
   }
   else
   {
		writeEnv(true);
   }
   return(INIT_SUCCEEDED);
}

void readEnv()
{
   Direction = GlobalVariableGet("Direction");
   CurrentTradeDirection = GlobalVariableGet("CurrentTradeDirection");
   	
   SourceUp = GlobalVariableGet("SourceUp");
   SourceDown = GlobalVariableGet("SourceDown");
   TargetUp = GlobalVariableGet("TargetUp");
   TargetDown = GlobalVariableGet("TargetDown");
   	
   NextLongPositionSize = GlobalVariableGet("NextLongPositionSize");
   NextShortPositionSize = GlobalVariableGet("NextShortPositionSize");
      
   drawLevels();
}
void writeEnv(bool reset)
{
   if(reset) {
   	Direction = -1;
   	CurrentTradeDirection = -1;
   	SourceUp = (Ask + ( (ZonePips/2) / digits ) );
   	SourceDown = (Ask - ( (ZonePips/2) / digits) );
   	TargetUp = SourceUp + ( TargetPips / digits ) ;
   	TargetDown = SourceDown - ( TargetPips / digits );
   	NextLongPositionSize = 0; 
   	NextShortPositionSize = 0;   
   }
   GlobalVariableSet("Direction", Direction);
   GlobalVariableSet("CurrentTradeDirection", CurrentTradeDirection);
   	
   GlobalVariableSet("SourceUp", SourceUp);
   GlobalVariableSet("SourceDown", SourceDown);
   GlobalVariableSet("TargetUp", TargetUp );
   GlobalVariableSet("TargetDown", TargetDown );
   	
   GlobalVariableSet("NextLongPositionSize", NextLongPositionSize);
   GlobalVariableSet("NextShortPositionSize", NextShortPositionSize);
      
   drawLevels();
}

void drawLevels()
{ 
   string comment = "INPUTS \n-----------------\nTargetPips = %G\nZonePips = %G\nFactor = %G\n\n"
                    "LEVELS \n-----------------\nSourceUp = %G\nSourceDown = %G\nTargetUp = %G\nTargetDown = %G\n\n"
                    "POSITIONS\n----------------\nCurrentLongPositionSize = %.2f\nCurrenttShortPositionSize = %.2f\nNextLongPositionSize = %.2f\nNextShortPositionSize = %.2f\nTotal Positions = %G\nDirection = %s";
   
   Comment(
      StringFormat(comment,
         TargetPips, 
         ZonePips, 
         Factor,
         SourceUp, 
         SourceDown, 
         TargetUp, 
         TargetDown,
         getCurrentPositionSize(OP_BUY),
         getCurrentPositionSize(OP_SELL),
         NextLongPositionSize, 
         NextShortPositionSize,         
         OrdersTotal(),
         (Direction == OP_BUY) ? "LONG" : ((Direction == OP_SELL) ? "SHORT" : "NONE")
      )
   );
   ObjectsDeleteAll();
    
   color targetUpColor = Yellow, targetDownColor = Yellow;
           
   if(Direction == OP_BUY)
   {
      targetUpColor = Green;
   }
   else if(Direction == OP_SELL)
   {
      targetDownColor = Green;
   }    
    
   string sourceUpName="SourceUp";
   if( ObjectCreate(sourceUpName,OBJ_HLINE,0,0,SourceUp) )
   {
       ObjectSet(sourceUpName,OBJPROP_COLOR,White);
       ObjectSet(sourceUpName,OBJPROP_STYLE,STYLE_DASH);
       ObjectSet(sourceUpName,OBJPROP_WIDTH,2); 
   }
   string sourceDownName="SourceDown";
   if( ObjectCreate(sourceDownName,OBJ_HLINE,0,0,SourceDown) )
   {
       ObjectSet(sourceDownName,OBJPROP_COLOR,White);
       ObjectSet(sourceDownName,OBJPROP_STYLE,STYLE_DASH);
       ObjectSet(sourceDownName,OBJPROP_WIDTH,2); 
   }
   
   string targetUpName="TargetUp";
   if( ObjectCreate(targetUpName,OBJ_HLINE,0,0,TargetUp) )
   {
      ObjectSet(targetUpName,OBJPROP_COLOR,targetUpColor);
      ObjectSet(targetUpName,OBJPROP_STYLE,STYLE_DASH);
      ObjectSet(targetUpName,OBJPROP_WIDTH,2); 
   }
 
   string targetDownName ="TargetDown";
   if( ObjectCreate(targetDownName,OBJ_HLINE,0,0,TargetDown) )
   {
      ObjectSet(targetDownName,OBJPROP_COLOR,targetDownColor);
      ObjectSet(targetDownName,OBJPROP_STYLE,STYLE_DASH);
      ObjectSet(targetDownName,OBJPROP_WIDTH,2); 
   }  
  
}

double getCurrentPositionSize(int type)
{
   double size = 0.0;
   for(int i=0;i<OrdersTotal();i++)
   {
      if( !OrderSelect(i,SELECT_BY_POS,MODE_TRADES) ) break;
      if(OrderMagicNumber() == MAGIC && OrderSymbol() == Symbol() && OrderType() == type) 
         size += OrderLots();   
   }
   return size;
}

bool closeOrders()
{
   for(int i=0;i<OrdersTotal();i++)
   {
    	if( !OrderSelect(i,SELECT_BY_POS,MODE_TRADES) ) break;
      if(OrderMagicNumber()!= MAGIC || OrderSymbol() != Symbol() ) continue;
      
      double price = (OrderType() == OP_BUY) ? Bid : Ask;
		if( !OrderClose(OrderTicket(),OrderLots(),price,MaxSlippage) )
      {
         Print("OrderClose error ",GetLastError());  
         return false;
      }
   }

	writeEnv(true);
   return true;
}

void openOrder(int trigger) {

   if (CurrentTradeDirection == trigger) return;
   if( Direction < 0 ) {
      Direction = trigger;
      NextLongPositionSize = (Direction == OP_BUY) ? LotSize : ( LotSize * Factor );
      NextShortPositionSize = (Direction == OP_SELL) ? LotSize : ( LotSize * Factor );
   }
   
   double nextPositionSize = 0;
	if( trigger ==  OP_BUY ) {
	   nextPositionSize = NextLongPositionSize;
	   NextLongPositionSize += nextPositionSize;
	} else if( trigger ==  OP_SELL ) {
      nextPositionSize = NextShortPositionSize;
      NextShortPositionSize += nextPositionSize;
	}
	
	double currentPositionSize = getCurrentPositionSize(trigger);
	nextPositionSize -= currentPositionSize;
	double price = (trigger == OP_BUY)? Ask : Bid;
	color clr = (trigger == OP_BUY)? Green : Red;
   if( !OrderSend(Symbol(), trigger,nextPositionSize, price, MaxSlippage,0,0,"Created with MyHedgeSystem",MAGIC,0,clr) ) {
	  Print("OrderSend error ",GetLastError());
	  return;  
   }	
	CurrentTradeDirection = trigger;
	writeEnv(false);
}


void OnTick()
{
	if( OrdersTotal() > 0 && (Ask > TargetUp || Bid < TargetDown ) )
	{
		closeOrders();
	}
   else if(Ask > SourceUp) 
   {
   	openOrder(OP_BUY);    
   }
   else if (Bid < SourceDown)
   {
		openOrder(OP_SELL); 
   }
}