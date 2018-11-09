unit FMX.ImageControls;

interface
  uses
  System.Rtti,
  System.Classes,
  System.Generics.Collections,
  System.Types,
  System.UITypes,
  FMX.Types,
  FMX.Controls,
  FMX.Layouts,
  FMX.Objects,
  FMX.Graphics,
  FMX.MultiResBitmap,
  FMX.TextLayout;

  type
   TBaseImageItem = class;
   TOnSelectItemChange = procedure (ASender : TBaseImageItem) of object;
   TOnBeforePicturePaint = procedure(ASender : TBaseImageItem) of object;
   TCustomImageScrooll = class;
   
   TSelectionIconPosition = (ipTopLeft, ipTopRight, ipBottomLeft, ipBottomRight, ipCenter);
   TOptionsSelection = class(TPersistent) 
    private  
     [weak]FScrool : TCustomImageScrooll;
     fMultiSelect : Boolean;
     fBorderColor : TAlphaColor;
     fOpacity : Boolean;
     fReduceImage : Boolean;
     fIcon : TCustomMultiResBitmap;
     fIconPosition : TSelectionIconPosition;
     procedure Repaint;
     procedure SetSelectionColor(const Value: TAlphaColor);
     procedure SetMiltiSelect(const Value: Boolean);
     procedure SetOpacity(const Value: Boolean);
     procedure SetIconPosition(const Value: TSelectionIconPosition);
     procedure ReadIconBitmap(Stream: TStream);
     procedure WriteIconBitmap(Stream: TStream);
     procedure SetIcon(const Value: TCustomMultiResBitmap); 
     function IconStored: Boolean;
     procedure ReadBorderColor(Reader: TReader);
     procedure ReadMultiSelect(Reader: TReader);
     procedure ReadOpacity(Reader: TReader);
     procedure ReadReduce(Reader: TReader);
     procedure WriteReduce(Writer: TWriter);
     procedure WriteBorderColor(Writer: TWriter);
     procedure WriteMultiSelect(Writer: TWriter);
     procedure WriteOpacity(Writer: TWriter);
     procedure SetReduce(const Value: Boolean);
    protected
     procedure AssignTo(Dest: TPersistent); override;
     procedure DefineProperties(Filer: TFiler); override;
    public 
     constructor Create(const [weak]AScrool : TCustomImageScrooll); reintroduce;
     destructor Destroy; override;
    published   
     property BorderColor : TAlphaColor read fBorderColor write SetSelectionColor;  
     property Icon : TCustomMultiResBitmap read fIcon write SetIcon;
     property IconPosition : TSelectionIconPosition read fIconPosition write SetIconPosition stored IconStored;
     property MultiSelect : Boolean read fMultiSelect write SetMiltiSelect;
     property Opacity : Boolean read fOpacity write SetOpacity;
     property ReduceImage : Boolean read fReduceImage write SetReduce;
   end;

   TImageList = class;
   TBaseImageItem = class(TImage)
    strict private
     fTL : TTextLayout;
     fMouseUpWait : Boolean;
     fMouseDownPoint : TPointF;
     fSelected : Boolean;
    private
     fList : TImageList;
     fOnSelectItemChange : TOnSelectItemChange;
     fOnBeforePaintItemPicture : TOnBeforePicturePaint;
     procedure SetSelected(const Value: Boolean);
    protected
     procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Single); override;
     procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Single); override;
     procedure Paint; override;
    public
     constructor Create(AOwner : TCustomImageScrooll); reintroduce;
     destructor Destroy; override;
     property Text : TTextLayout read fTL;
     property Selected : Boolean read fSelected write SetSelected;
     property OnSelectItemChange : TOnSelectItemChange read fOnSelectItemChange write fOnSelectItemChange;
     property OnBeforePaintItemPicture : TOnBeforePicturePaint read fOnBeforePaintItemPicture write fOnBeforePaintItemPicture;
   end;


   TImageList = class(TList<TBaseImageItem>)
    private
     [weak]FScrool : TCustomImageScrooll;
    protected
     procedure Notify(const Value: TBaseImageItem; Action: TCollectionNotification); override;
    public
     constructor Create(const [weak]AScrool : TCustomImageScrooll); reintroduce;
     function CreateItem<T : TBaseImageItem>: T;
   end;

   TImageItemClass = class of TBaseImageItem;

   TCustomImageScrooll = class(TCustomScrollBox)
    private
     fItems : TImageList;
     fOffset : Single;
     fOptionsSelection : TOptionsSelection;
     procedure OnItemBitmapChanged(Sender: TObject);
     procedure SetOffset(const Value: Single);
     procedure ClearSelection(const ExceptItem : TBaseImageItem); overload;
    protected
     procedure UpdatePictures; virtual; abstract;
     function GetDefaultStyleLookupName: string; override;
     procedure Paint; override;
     procedure HandleSizeChanged; override;
    public
     constructor Create(AOwner: TComponent); override;
     destructor Destroy; override;
     procedure DoEndUpdate; override;
     property Items : TImageList read fItems;
     property Offset : Single read fOffset write SetOffset;
     function SelectedCount : Integer;
     procedure ClearSelection; overload; 
     function ItemVisible(const AItem : TBaseImageItem): Boolean;
     property OptionsSelection : TOptionsSelection read fOptionsSelection;
   end;

   TBarStretchMode = (smVertical, smHorizontal);
   TCustomImageBar = class(TCustomImageScrooll)
    private
     fMode : TBarStretchMode;
     procedure SetMode(const Value: TBarStretchMode);
    protected
     procedure UpdatePictures; override;
     function DoCalcContentBounds: TRectF; override;
     procedure DoUpdateAniCalculations(const AAniCalculations: TScrollCalculations); override;
    public
     constructor Create(AOwner: TComponent); override;
     property Mode: TBarStretchMode read FMode write SetMode;
   end;

   TImageBar = class(TCustomImageBar)
    published
     property Offset; 
     property Mode;
     property OptionsSelection;
   end;

implementation
uses
System.SysUtils;

type
  TBaseImageItemClass = class of TBaseImageItem;

{ TImageGrid }

constructor TCustomImageScrooll.Create(AOwner: TComponent);
begin
  inherited;
  fOptionsSelection := TOptionsSelection.Create(self);
  fItems := TImageList.Create(self);
end;

destructor TCustomImageScrooll.Destroy;
begin
  fItems.FScrool := nil;
  FreeAndNil(fItems);
  inherited Destroy;
end;
function TCustomImageScrooll.GetDefaultStyleLookupName: string;
begin
  Result := 'scrollboxstyle';
end;

procedure TCustomImageScrooll.HandleSizeChanged;
begin
  inherited;
  if not IsUpdating then
    UpdatePictures;
end;

function TCustomImageScrooll.ItemVisible(const AItem: TBaseImageItem): Boolean;
var
  vPosition,
  vItemLeftTop,
  vItemRightBottom : TPointF;
  vViewRect : TRectF;
begin
  vPosition := ViewportPosition;
  vViewRect := TRectF.Create(vPosition, Width, Height);
  vItemLeftTop := AItem.Position.Point;
  vItemRightBottom := TPointF.Create(vItemLeftTop.X + AItem.Width, vItemLeftTop.Y + AItem.Height);
  result := vViewRect.Contains(AItem.Position.Point) or vViewRect.Contains(vItemRightBottom);
end;

procedure TCustomImageScrooll.Paint;
begin
  inherited Paint;
  if (csDesigning in ComponentState) and not Locked then
    DrawDesignBorder(DesignBorderColor, DesignBorderColor or TAlphaColorRec.Alpha);
end;

procedure TCustomImageScrooll.DoEndUpdate;
begin
  inherited;
  UpdatePictures;
end;

procedure TCustomImageScrooll.ClearSelection(const ExceptItem: TBaseImageItem);
var
  i : Integer;
begin
  i := 0;
  while i < fItems.Count do
  begin
    if fItems[i].Selected and (fItems[i] <> ExceptItem) then
      fItems[i].Selected := False;
    Inc(i);
  end;
end;

procedure TCustomImageScrooll.ClearSelection;
begin
  ClearSelection(nil);
end;

procedure TCustomImageScrooll.OnItemBitmapChanged(Sender: TObject);
var
  i : Integer;
begin
  if not (Sender is TBitmap) then
    Exit;
  i := 0;
  while i < fItems.Count do
  begin
    if fItems[i].Bitmap = Sender then
      Break;
    Inc(i);
  end;
  if i >= fItems.Count then
    Exit;
  if (fItems[i].Top <= Height) or (fItems[i].Left <= Width)  then
    Repaint;
end;

function TCustomImageScrooll.SelectedCount: Integer;
var
  i : Integer;
begin
  i := 0;
  result := 0;
  while i < fItems.Count do
  begin
    if fItems[i].Selected then
      Inc(result);
    Inc(i);
  end;
end;

procedure TCustomImageScrooll.SetOffset(const Value: Single);
begin
  fOffset := Value;
  if not IsUpdating then
    UpdatePictures;
end; 

{TOptionsSelection} 

procedure TOptionsSelection.AssignTo(Dest: TPersistent);
var
 vDest : TOptionsSelection;
begin
  if Dest is TOptionsSelection then
  begin
    vDest := Dest as TOptionsSelection;
    vDest.Opacity := Opacity;
    vDest.BorderColor := BorderColor;
    vDest.MultiSelect := MultiSelect;
    vDest.Icon.Assign(Icon);
  end;
end;

constructor TOptionsSelection.Create(const AScrool: TCustomImageScrooll);
begin
  inherited Create;
  fOpacity := False;
  fReduceImage := True;
  fBorderColor := $FF09C9DF;
  fMultiSelect := False;
  fIcon := TCustomMultiResBitmap.Create(Self, TCustomBitmapItem);
  FScrool := AScrool; 
end;

procedure TOptionsSelection.DefineProperties(Filer: TFiler);
begin
  inherited;
  Filer.DefineProperty('MultiSelect', ReadMultiSelect, WriteMultiSelect, true);
  Filer.DefineProperty('Opacity', ReadOpacity, WriteOpacity, true);
  Filer.DefineProperty('Reduce', ReadReduce, WriteReduce, true);
  Filer.DefineProperty('BorderColor', ReadBorderColor, WriteBorderColor, true);
  Filer.DefineBinaryProperty('SelIcoBitmap', ReadIconBitmap, WriteIconBitmap, False);
end;

procedure TOptionsSelection.ReadOpacity(Reader: TReader);
begin
  fOpacity := Reader.ReadBoolean;
end;

procedure TOptionsSelection.WriteOpacity(Writer: TWriter);
begin
  Writer.WriteBoolean(fOpacity);
end;

procedure TOptionsSelection.ReadReduce(Reader: TReader);
begin
  fReduceImage := Reader.ReadBoolean;
end;

procedure TOptionsSelection.WriteReduce(Writer: TWriter);
begin
  Writer.WriteBoolean(fReduceImage);
end;

procedure TOptionsSelection.ReadBorderColor(Reader: TReader);
begin
  fBorderColor := TAlphaColor(Reader.ReadInteger);
end;

procedure TOptionsSelection.WriteBorderColor(Writer: TWriter);
begin
  Writer.WriteInteger(Integer(fBorderColor));
end;

procedure TOptionsSelection.ReadMultiSelect(Reader: TReader);
begin
  fMultiSelect := Reader.ReadBoolean;
end;

procedure TOptionsSelection.WriteMultiSelect(Writer: TWriter);
begin
  Writer.WriteBoolean(fMultiSelect);
end;

destructor TOptionsSelection.Destroy;
begin
  FreeAndNil(fIcon);
  inherited;
end;

function TOptionsSelection.IconStored: Boolean;
var
  I: Integer;
begin
  Result := (fIcon.TransparentColor <> TColors.SysNone) or
            (fIcon.SizeKind <> TSizeKind.Custom) or
            (fIcon.Width <> fIcon.DefaultSize.cx) or
            (fIcon.Height <> fIcon.DefaultSize.cy);
  if not Result then
  begin
    for I := 0 to fIcon.Count - 1 do
    begin
      if (fIcon[I].FileName <> '') or
         (not fIcon[I].IsEmpty) then
      begin
        Result := True;
        Exit;
      end;
    end;
  end;
end;

procedure TOptionsSelection.ReadIconBitmap(Stream: TStream);
begin
  FIcon.LoadFromStream(Stream);
end; 

procedure TOptionsSelection.WriteIconBitmap(Stream: TStream);
begin
  FIcon.SaveToStream(Stream);
end;  

procedure TOptionsSelection.Repaint;
var
  i : Integer;
begin
  i := 0;
  while i < FScrool.Items.Count do
  begin
    if FScrool.Items[i].Selected and FScrool.ItemVisible(FScrool.Items[i]) then
      FScrool.Items[i].Repaint;
    Inc(i);
  end;
end;

procedure TOptionsSelection.SetIcon(const Value: TCustomMultiResBitmap);
begin
  fIcon.Assign(Value);
end;

procedure TOptionsSelection.SetIconPosition(const Value: TSelectionIconPosition);
begin
  fIconPosition := Value;
  if fIconPosition = Value then
    Exit;
  fIconPosition := Value;
  Repaint;
end;

procedure TOptionsSelection.SetMiltiSelect(const Value: Boolean);
var
  i : Integer;
  vSC : Integer;
begin
  fMultiSelect := Value;
  if not fMultiSelect then
  begin
    vSC := FScrool.SelectedCount;
    if vSC < 2 then
      Exit;
    i := 0;
    while i < FScrool.Items.Count do
    begin
      if FScrool.Items[i].Selected then
      begin
        FScrool.Items[i].Selected := False;
        Inc(vSC);
        if vSC < 2 then
          Break;
      end;
      Inc(i);
    end;
  end;
end;

procedure TOptionsSelection.SetOpacity(const Value: Boolean);
begin
  if fOpacity = Value then
    Exit;
  fOpacity := Value;
  Repaint;
end;

procedure TOptionsSelection.SetReduce(const Value: Boolean);
begin
  if fReduceImage = Value then
    Exit;
  fReduceImage := Value;
  Repaint;
end;

procedure TOptionsSelection.SetSelectionColor(const Value: TAlphaColor);
begin
  if fBorderColor = Value then
    Exit;
  fBorderColor := Value;
  Repaint;
end;

{TImageBar}

constructor TCustomImageBar.Create(AOwner: TComponent);
begin
  inherited;
  fMode := smHorizontal;
  fOffset := 5;
end;

function TCustomImageBar.DoCalcContentBounds: TRectF;
begin
  case fMode of
    smVertical:
    begin
      if (Content <> nil) and (ContentLayout <> nil) then
        Content.Width := ContentLayout.Width; // Only for compatibility with old code
      Result := inherited DoCalcContentBounds;
      if ContentLayout <> nil then
        Result.Width := ContentLayout.Width;
    end;
    smHorizontal:
    begin
      if (Content <> nil) and (ContentLayout <> nil) then
        Content.Height := ContentLayout.Height; // Only for compatibility with old code
      Result := inherited DoCalcContentBounds;
      if ContentLayout <> nil then
        Result.Height := ContentLayout.Height;
    end;
  end;
end;

procedure TCustomImageBar.DoUpdateAniCalculations(const AAniCalculations: TScrollCalculations);
begin
  case fMode of
    smVertical:
    begin
      inherited DoUpdateAniCalculations(AAniCalculations);
      AAniCalculations.TouchTracking := AAniCalculations.TouchTracking - [ttHorizontal];
    end;
    smHorizontal:
    begin
      inherited DoUpdateAniCalculations(AAniCalculations);
      AAniCalculations.TouchTracking := AAniCalculations.TouchTracking - [ttVertical];
    end;
  end;
end;

procedure TCustomImageBar.SetMode(const Value: TBarStretchMode);
begin
  FMode := Value;
  DoRealign;
  if not IsUpdating then
    UpdatePictures;
end;

procedure TCustomImageBar.UpdatePictures;
var
  i : Integer;
  vPictureCoord : TPointF;
  vImg : TBaseImageItem;
begin
  if IsUpdating or (fItems.Count < 1) then
    Exit;
  i := 0;
  while i < fItems.Count do
  begin
    vImg := fItems[i];
    case fMode of
      smVertical:
      begin
        vImg.Height := Self.Width;
        vImg.Width := Self.Width;
        vImg.Align := TAlignLayout.Horizontal;
      end;
      smHorizontal:
      begin
        vImg.Height := Self.Height;
        vImg.Width := Self.Height;
        vImg.Align := TAlignLayout.Vertical;
      end;
    end;
    Inc(i);
  end;
  i := 0;
  vPictureCoord := TPointF.Create(fOffset, fOffset);
  while i < fItems.Count do
  begin
    vImg := fItems[i];
    vImg.Position.Point := vPictureCoord;
    case fMode of
      smVertical:
      begin
        vPictureCoord.Y := vImg.Position.Y + vImg.Height + fOffset;
      end;
      smHorizontal:
      begin
        vPictureCoord.X := vImg.Position.X + vImg.Width + fOffset;
      end;
    end;
    Inc(i);
  end;
end;

{ TImageGrid.TImageList }

constructor TImageList.Create(const [weak]AScrool: TCustomImageScrooll);
begin
  FScrool := AScrool;
  inherited Create;
end;

function TImageList.CreateItem<T>: T;
begin
  TBaseImageItem(result) := TBaseImageItemClass(T).Create(FScrool);
  TBaseImageItem(result).fList := self;
  TBaseImageItem(result).Align := TAlignLayout.None;
  TBaseImageItem(result).Bitmap.OnChange := FScrool.OnItemBitmapChanged;
  self.Add(TBaseImageItem(result));
end;

procedure TImageList.Notify(const Value: TBaseImageItem; Action: TCollectionNotification);
begin
  if Action = TCollectionNotification.cnRemoved then
    Value.DisposeOf;
  inherited;
  if Assigned(FScrool) and (not FScrool.IsUpdating) and FScrool.CanRepaint then
      FScrool.UpdatePictures;
end;

{ TImageGrid.TGridImage }

constructor TBaseImageItem.Create(AOwner: TCustomImageScrooll);
begin
  inherited Create(AOwner);
  Parent := AOwner;
  fSelected := False;
  fTL := TTextLayoutManager.DefaultTextLayout.Create(Canvas);
  fTL.HorizontalAlign := TTextAlign.Center;
  fTL.VerticalAlign := TTextAlign.Center;
  fTL.Padding.Bottom := 3;
  Visible := true;
end;

destructor TBaseImageItem.Destroy;
var
 i : Integer;
begin
  try
    i := fList.IndexOf(self);
    if i <> -1 then
      fList.Delete(i);
  finally
    fTL.Free;
    inherited Destroy;
  end;
end;

procedure TBaseImageItem.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  inherited;
  fMouseUpWait := True;
  fMouseDownPoint := TPointF.Create(X, Y);
end;

procedure TBaseImageItem.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Single);
var
 vMouseUpPoint : TPointF;
begin
  inherited;
  if fMouseUpWait then
  begin
    vMouseUpPoint := TPointF.Create(X, Y);
    if fMouseDownPoint.Distance(vMouseUpPoint) < 5 then
    begin
      Selected := not fSelected;
      if Assigned(fOnSelectItemChange) then
        fOnSelectItemChange(Self);
      Repaint;
    end;
  end;
  fMouseUpWait := False;
end;

procedure TBaseImageItem.Paint;
var
  vScale: Single;
  vIconItem: TCustomBitmapItem;

  function IconFound(var oItem: TCustomBitmapItem): Boolean;
  begin
    vScale := 0;
    if Scene <> nil then
      vScale := Scene.GetSceneScale
    else
      vScale := 1.0;

    oItem := TCustomImageScrooll(Owner).OptionsSelection.Icon.ItemByScale(vScale, False, false);
    if oItem <> nil then
      vScale := oItem.Scale;

    Result := (oItem <> nil) and not oItem.IsEmpty;
  end;

var
  iR, bR: TRectF; //Image rect, Border rect
  tP : TPointF; // Text top-felt point
  procedure InternalDrawSelectionImage;
  var
   icR : TRectF;
  begin
    Self.Canvas.Fill.Color := TCustomImageScrooll(Owner).OptionsSelection.BorderColor;
    Self.Canvas.FillRect(bR, 0, 0, [], AbsoluteOpacity/2, TCornerType.Round);
    if TCustomImageScrooll(Owner).OptionsSelection.Opacity then
      DrawBitmap(Self.Canvas, iR, Bitmap, AbsoluteOpacity/2)
    else
      DrawBitmap(Self.Canvas, iR, Bitmap, AbsoluteOpacity);
    if IconFound(vIconItem) then
    begin
      icR := iR;
      case TCustomImageScrooll(Owner).OptionsSelection.IconPosition of
        ipTopLeft:
        begin
          icR.Bottom := vIconItem.Height;
          icR.Right := vIconItem.Width;
        end;
        ipTopRight:
        begin
          icR.Bottom := icR.Height - vIconItem.Height;
          icR.Left := icR.Width - vIconItem.Width;
        end;
        ipBottomLeft:
        begin
          icR.Top := icR.Height - vIconItem.Height;
          icR.Right := vIconItem.Width;
        end;
        ipBottomRight:
        begin
          icR.Top := icR.Height - vIconItem.Height;
          icR.Right := vIconItem.Width;
        end;
        ipCenter:
        begin
          icR.Bottom := vIconItem.Height;
          icR.Right := vIconItem.Width;
          icR := RectCenter(icR, iR);
        end;
      end;
      DrawBitmap(Self.Canvas, icR, vIconItem, AbsoluteOpacity);
    end;
  end;
begin
  if Assigned(fOnBeforePaintItemPicture) then
    fOnBeforePaintItemPicture(Self);
  if not fTL.Text.IsEmpty then
  begin
    iR := LocalRect;
    iR.Top := iR.Top + 3;
    iR.Bottom := iR.Bottom - (fTL.TextHeight + fTL.Padding.Bottom);
    iR.Height := RectHeight(iR);
    if not fSelected then
      DrawBitmap(Self.Canvas, iR, Bitmap, AbsoluteOpacity)
    else
    begin
      bR := LocalRect;
      InternalDrawSelectionImage;
    end;
    tP := TPointF.Create(iR.Left, iR.Bottom);
    fTL.TopLeft := tP;
    tP.X := iR.Width;
    tP.Y := LocalRect.Height - iR.Height;
    fTL.MaxSize := tP;
    fTL.RenderLayout(Self.Canvas);
  end else if fSelected then
  begin
    bR := LocalRect;
    iR := bR;
    if TCustomImageScrooll(Owner).OptionsSelection.ReduceImage then
      InflateRect(iR, -iR.Left * 0.1, - iR.Bottom * 0.1);
    InternalDrawSelectionImage;
  end else
    inherited Paint;
end;

procedure TBaseImageItem.SetSelected(const Value: Boolean);
begin
  if fSelected = Value then
    Exit;
  if Value and not TCustomImageScrooll(Owner).OptionsSelection.MultiSelect then
    TCustomImageScrooll(Owner).ClearSelection(self);
  fSelected := Value;
  if TCustomImageScrooll(Owner).ItemVisible(self) then
    Repaint;
end;

end.
