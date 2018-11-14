//+------------------------------------------------------------------+
//|                                                 MyGridSystem.mq4 |
//|                                                 Hanuma Munjuluri |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Hanuma Munjuluri"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

#define MAGIC  20180901


input double RiskPercent = 1;
input int Gap = 20;
double digits = 10000.0;
double GapPips = Gap / digits;

double Upper = 0;
double Lower = 0;
double Mid = 0;

int MaxSlippage=3;
input double MaxSpread = 4;

int OnInit()
{
   Mid = GlobalVariableGet("Mid");
   
   if( Mid > 0 && isOrderOpen(OP_BUY) ) 
   {
      setLevels(Mid, OP_BUY); 
   }
   else if( Mid > 0 && isOrderOpen(OP_SELL) )
   {
      setLevels(Mid, OP_SELL); 
   }
   else
   {
      setLevels(Ask, -1);
   }
   
   return(INIT_SUCCEEDED);
}

void setLevels(double mid, int direction)
{
    Mid = mid;
    Upper = Mid + GapPips;
    Lower = Mid - GapPips;
    
    GlobalVariableSet("Mid", Mid);
   
    Comment(StringFormat("LEVELS \n-----------------\nUpper = %G\nMid = %G\nLower = %G\n",Upper,Mid,Lower));
   
    ObjectsDeleteAll();
        
    color upperColor = Yellow;
    color lowerColor = Yellow;     
    if(direction == OP_BUY)
    {
      upperColor = Green;
      lowerColor = Red;
    }
    else if(direction == OP_SELL)
    {
      upperColor = Red;
      lowerColor = Green;    
    }    
    
    string midName="Mid";
    if( ObjectCreate(midName,OBJ_HLINE,0,0,Mid) )
    {
        ObjectSet(midName,OBJPROP_COLOR,Yellow);
        ObjectSet(midName,OBJPROP_STYLE,STYLE_DASH);
        ObjectSet(midName,OBJPROP_WIDTH,2); 
    }
   
    string upperName="Upper";
    if( ObjectCreate(upperName,OBJ_HLINE,0,0,Upper) )
    {
      ObjectSet(upperName,OBJPROP_COLOR,upperColor);
      ObjectSet(upperName,OBJPROP_STYLE,STYLE_DASH);
      ObjectSet(upperName,OBJPROP_WIDTH,2); 
    }
   
    string lowerName="Lower";
    if ( ObjectCreate(lowerName,OBJ_HLINE,0,0,Lower) )
    {
      ObjectSet(lowerName,OBJPROP_COLOR,lowerColor);
      ObjectSet(lowerName,OBJPROP_STYLE,STYLE_DASH);
      ObjectSet(lowerName,OBJPROP_WIDTH,2);  
    }    
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   ObjectsDeleteAll();
}

bool isOrderOpen(int type)
{
   for(int i=0;i<OrdersTotal();i++)
   {
      if( !OrderSelect(i,SELECT_BY_POS,MODE_TRADES) ) break;
      if(OrderMagicNumber() == MAGIC && OrderSymbol() == Symbol() && OrderType() == type) 
         return true;
      
   }
   return false;
}

bool closeOppositeOrders(int direction)
{
   for(int i=0;i<OrdersTotal();i++)
   {
      if( !OrderSelect(i,SELECT_BY_POS,MODE_TRADES) ) break;
      if(OrderMagicNumber()!= MAGIC || OrderSymbol() != Symbol() || OrderType() != direction) continue;
      
      if(direction == OP_BUY) 
      {
         if( !OrderClose(OrderTicket(),OrderLots(),Bid,MaxSlippage) )
         {
            Print("OrderClose error ",GetLastError());  
            return false;
         }
      }
      else if(direction == OP_SELL)
      {
         if( !OrderClose(OrderTicket(),OrderLots(),Ask,MaxSlippage) )
         {
            Print("OrderClose error ",GetLastError());
            return false;
         }
      }
   }
   return true;
}


double calculateLotSize()
{
   double tickvalue = (MarketInfo(Symbol(),MODE_TICKVALUE));
   if(Digits == 5 || Digits == 3){
      tickvalue = tickvalue*10;
   }

   double riskcapital = AccountBalance()*RiskPercent/100;
   
   double Lots=(riskcapital/Gap)/tickvalue;
   Lots = NormalizeDouble( Lots, Digits );

   if(Lots<MarketInfo(Symbol(),MODE_MINLOT))
      Lots=MarketInfo(Symbol(),MODE_MINLOT);
   if(Lots>MarketInfo(Symbol(),MODE_MAXLOT))
      Lots=MarketInfo(Symbol(),MODE_MAXLOT);
      
   return Lots;
}

void openOrder(int direction)
{
   if( isOrderOpen(direction) ) return;
   
   double Lots = calculateLotSize();
   double price = (direction == OP_BUY) ? Ask : Bid;
   color clr = (direction == OP_BUY) ? Green : Red;
   
   double spread = MathAbs(Ask-Bid) * digits;
   if( spread > MaxSpread ) return;
   
   if( !OrderSend(Symbol(),direction,Lots,price, MaxSlippage,0,0,"Created with MyGridSystem",MAGIC,0,clr) )
      Print("OrderSend error ",GetLastError());      
}
  
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   if(Ask > Upper) 
   {
      setLevels(Ask, OP_BUY);
      
      if( closeOppositeOrders(OP_SELL) ) // Close opposite order
      {
         openOrder(OP_BUY); // Open new order
      }          
   }
   else if (Bid < Lower)
   {
      setLevels(Bid, OP_SELL);
      
      if( closeOppositeOrders(OP_BUY) ) // Close opposite order
      {
         openOrder(OP_SELL); // Open new order
      }   
   }
}
//+------------------------------------------------------------------+
