unit Tr.FMX.ImageControls;

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
   TOptionsSelection = class(TInterfacedPersistent)
    private  
     [weak]FScrool : TCustomImageScrooll;
     //FNotifyList: TList<Pointer>;
     fMultiSelect : Boolean;
     fBorderColor : TAlphaColor;
     fOpacity : Boolean;
     fReduceImage : Boolean;
     fIcon : TBitmap;
     fIconPosition : TSelectionIconPosition;
     procedure Repaint;
     procedure SetSelectionColor(const Value: TAlphaColor);
     procedure SetMiltiSelect(const Value: Boolean);
     procedure SetOpacity(const Value: Boolean);
     procedure SetIconPosition(const Value: TSelectionIconPosition);
     procedure SetIcon(const Value: TBitmap);
     procedure SetReduce(const Value: Boolean);
     {procedure ReadIconBitmap(Stream: TStream);
     procedure WriteIconBitmap(Stream: TStream);
     function IconStored: Boolean;
     procedure ReadBorderColor(Reader: TReader);
     procedure ReadMultiSelect(Reader: TReader);
     procedure ReadOpacity(Reader: TReader);
     procedure ReadReduce(Reader: TReader);
     procedure WriteReduce(Writer: TWriter);
     procedure WriteBorderColor(Writer: TWriter);
     procedure WriteMultiSelect(Writer: TWriter);
     procedure WriteOpacity(Writer: TWriter);
     procedure ReadIconPosition(Reader: TReader);
     procedure WriteIconPosition(Writer: TWriter);  }
    protected
     procedure AssignTo(Dest: TPersistent); override;
     //procedure DefineProperties(Filer: TFiler); override;
    public 
     constructor Create(const [weak]AScrool : TCustomImageScrooll); reintroduce;
     destructor Destroy; override;
    published
     property BorderColor : TAlphaColor read fBorderColor write SetSelectionColor stored true;
     property Icon : TBitmap read fIcon write SetIcon;// stored IconStored;
     property IconPosition : TSelectionIconPosition read fIconPosition write SetIconPosition;// stored IconStored;
     property MultiSelect : Boolean read fMultiSelect write SetMiltiSelect;// stored true;
     property Opacity : Boolean read fOpacity write SetOpacity;// stored true;
     property ReduceImage : Boolean read fReduceImage write SetReduce;// stored true;
   end;

   TImageItems = class;
   TBaseImageItem = class(TImage)
    strict private
     fTL : TTextLayout;
     fMouseUpWait : Boolean;
     fMouseDownPoint : TPointF;
     fSelected : Boolean;
    private
     fList : TImageItems;
     fOnSelectItemChange : TOnSelectItemChange;
     fOnBeforePaintItemPicture : TOnBeforePicturePaint;
     procedure SetSelected(const Value: Boolean);
     procedure OnBitmapChanged(Sender: TObject);
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

   TBaseImageItemClass = class of TBaseImageItem;

   TImageItems = class(TList<TBaseImageItem>)
    private
     [weak]FScrool : TCustomImageScrooll;
    protected
     procedure Notify(const Value: TBaseImageItem; Action: TCollectionNotification); override;
    public
     constructor Create(const [weak]AScrool : TCustomImageScrooll); reintroduce;
     function CreateItem<T : TBaseImageItem>: T;
   end;

   TSelectedImageItems = class(TList<TBaseImageItem>)
    protected
     procedure Notify(const Value: TBaseImageItem; Action: TCollectionNotification); override;
   end;

   TImageItemClass = class of TBaseImageItem;

   TCustomImageScrooll = class(TCustomScrollBox)
    private
     fItems : TImageItems;
     fSelectedItems : TSelectedImageItems;
     fOffset : Single;
     fOptionsSelection : TOptionsSelection;
     procedure SetOffset(const Value: Single);
     procedure ClearSelection(const ExceptItem : TBaseImageItem); overload;
     procedure SetOptionsSelection(const Value: TOptionsSelection);
    protected
     procedure UpdatePictures; virtual; abstract;
     function GetDefaultStyleLookupName: string; override;
     procedure Paint; override;
     procedure DoRealign; override;
    public
     constructor Create(AOwner: TComponent); override;
     destructor Destroy; override;
     procedure DoEndUpdate; override;
     property Items : TImageItems read fItems;
     property SelectedItems : TSelectedImageItems read fSelectedItems;
     property Offset : Single read fOffset write SetOffset;
     procedure ClearSelection; overload; 
     function ItemVisible(const AItem : TBaseImageItem): Boolean;
     property OptionsSelection : TOptionsSelection read fOptionsSelection write SetOptionsSelection stored true;
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

   TCustomImageGrid = class(TCustomImageScrooll)
    private
     fItemSize : TSizeF;
     procedure SetItemSize(const Value: TSizeF);
    protected
     procedure UpdatePictures; override;
     function DoCalcContentBounds: TRectF; override;
     procedure DoUpdateAniCalculations(const AAniCalculations: TScrollCalculations); override;
    public
     constructor Create(AOwner: TComponent); override;
     property ItemSize : TSizeF read fItemSize write SetItemSize;
   end;

   TImageBar = class(TCustomImageBar)
    published
     property Offset;
     property Mode;
     property OptionsSelection;
   end;

   TImageGrid = class(TCustomImageGrid)
    published
     property Offset;
     property ItemSize;
     property OptionsSelection;
   end;

procedure Register;

implementation
uses
System.SysUtils;

procedure Register;
begin
  RegisterComponents('TrControls', [TImageBar, TImageGrid]);
end;

{ TImageGrid }

constructor TCustomImageScrooll.Create(AOwner: TComponent);
begin
  inherited;
  fOffset := 5;
  fOptionsSelection := TOptionsSelection.Create(self);
  fItems := TImageItems.Create(self);
  fSelectedItems := TSelectedImageItems.Create;
end;

destructor TCustomImageScrooll.Destroy;
begin
  ClearSelection;
  FreeAndNil(fSelectedItems);
  fItems.FScrool := nil;
  FreeAndNil(fItems);
  inherited Destroy;
end;
function TCustomImageScrooll.GetDefaultStyleLookupName: string;
begin
  Result := 'scrollboxstyle';
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

procedure TCustomImageScrooll.DoRealign;
begin
  inherited DoRealign;
  if not IsUpdating then
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

procedure TCustomImageScrooll.SetOffset(const Value: Single);
begin
  fOffset := Value;
  if not IsUpdating then
    UpdatePictures;
end; 

procedure TCustomImageScrooll.SetOptionsSelection(const Value: TOptionsSelection);
begin
  fOptionsSelection.AssignTo(Value);
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
    vDest.IconPosition := IconPosition;
    vDest.ReduceImage := ReduceImage;
    vDest.Icon.Assign(Icon);
  end;
end;

constructor TOptionsSelection.Create(const [weak]AScrool : TCustomImageScrooll);
begin
  inherited Create;
  fOpacity := False;
  fReduceImage := True;
  fBorderColor := $FF09C9DF;
  fMultiSelect := False;
  fIcon := TBitmap.Create;
  FScrool := AScrool; 
end;

destructor TOptionsSelection.Destroy;
begin
  FreeAndNil(fIcon);
  inherited;
end;

{procedure TOptionsSelection.DefineProperties(Filer: TFiler);
begin
  inherited;
  Filer.DefineProperty('MultiSelect', ReadMultiSelect, WriteMultiSelect, true);
  Filer.DefineProperty('Opacity', ReadOpacity, WriteOpacity, true);
  Filer.DefineProperty('Reduce', ReadReduce, WriteReduce, true);
  Filer.DefineProperty('BorderColor', ReadBorderColor, WriteBorderColor, true);
  Filer.DefineProperty('IconPosition', ReadIconPosition, WriteIconPosition, IconStored);
  Filer.DefineBinaryProperty('SelIcoBitmap', ReadIconBitmap, WriteIconBitmap, IconStored);
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

procedure TOptionsSelection.ReadIconPosition(Reader: TReader);
begin
  fIconPosition := TSelectionIconPosition(Reader.ReadInteger);
end;

procedure TOptionsSelection.WriteIconPosition(Writer: TWriter);
begin
  Writer.WriteInteger(Integer(fIconPosition));
end;

procedure TOptionsSelection.ReadMultiSelect(Reader: TReader);
begin
  fMultiSelect := Reader.ReadBoolean;
end;

procedure TOptionsSelection.WriteMultiSelect(Writer: TWriter);
begin
  Writer.WriteBoolean(fMultiSelect);
end;

function TOptionsSelection.IconStored: Boolean;
begin
  Result := not fIcon.IsEmpty;
end;

procedure TOptionsSelection.ReadIconBitmap(Stream: TStream);
begin
  FIcon.LoadFromStream(Stream);
end; 

procedure TOptionsSelection.WriteIconBitmap(Stream: TStream);
begin
  FIcon.SaveToStream(Stream);
end;  }

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

procedure TOptionsSelection.SetIcon(const Value: TBitmap);
begin
  fIcon.Assign(Value);
  Repaint;
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
begin
  fMultiSelect := Value;
  if not fMultiSelect then
  begin
    while FScrool.SelectedItems.Count > 1 do
      FScrool.SelectedItems.Delete(0);
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



{ TCustomImageGrid }

constructor TCustomImageGrid.Create(AOwner: TComponent);
begin
  inherited;
  fItemSize := TSizeF.Create(90, 90);
end;

function TCustomImageGrid.DoCalcContentBounds: TRectF;
begin
  if (Content <> nil) and (ContentLayout <> nil) then
    Content.Width := ContentLayout.Width; // Only for compatibility with old code
  Result := inherited DoCalcContentBounds;
  if ContentLayout <> nil then
    Result.Width := ContentLayout.Width;
end;

procedure TCustomImageGrid.DoUpdateAniCalculations(const AAniCalculations: TScrollCalculations);
begin
  inherited DoUpdateAniCalculations(AAniCalculations);
      AAniCalculations.TouchTracking := AAniCalculations.TouchTracking - [ttHorizontal];
end;

procedure TCustomImageGrid.SetItemSize(const Value: TSizeF);
begin
  if fItemSize <> Value then
    Exit;
  fItemSize := Value;
  UpdatePictures;
end;

procedure TCustomImageGrid.UpdatePictures;
var
  i : Integer;
  vPictureCoord : TPointF;
  vImg : TBaseImageItem;
begin
  if IsUpdating or (fItems.Count < 1) then
    Exit;
  vPictureCoord := TPointF.Create(fOffset, fOffset);
  i := 0;
  while i < fItems.Count do
  begin
    vImg := fItems[i];
    vImg.Align := TAlignLayout.None;
    vImg.Left := vPictureCoord.X;
    vImg.Top := vPictureCoord.Y;
    vImg.Position.Point := vPictureCoord;
    vImg.Height := fItemSize.Height;
    vImg.Width := fItemSize.Width;
    if (vImg.Left + vImg.Width + Offset + fItemSize.Width > self.Width) then
    begin
      vPictureCoord.X := Offset;
      vPictureCoord.Y := vPictureCoord.Y + fItemSize.Height + Offset;
    end else
      vPictureCoord.X := vImg.Left + vImg.Width + Offset;
    Inc(i);
  end;
end;

{ TBaseImageItem }

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
  self.Bitmap.OnChange := OnBitmapChanged;
end;

destructor TBaseImageItem.Destroy;
var
 i : Integer;
begin
  try
    fSelected := False;
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

procedure TBaseImageItem.OnBitmapChanged(Sender: TObject);
begin
  if TCustomImageScrooll(Owner).ItemVisible(Self) then
    Repaint;
end;

procedure TBaseImageItem.Paint;
var
  iR, bR: TRectF; //Image rect, Border rect
  tP : TPointF; // Text top-felt point
  procedure InternalDrawSelectionImage;
  var
   icR : TRectF;
   vIcon : TBitmap;
  begin
    Self.Canvas.Fill.Color := TCustomImageScrooll(Owner).OptionsSelection.BorderColor;
    Self.Canvas.FillRect(bR, 0, 0, [], AbsoluteOpacity/2, TCornerType.Round);
    if TCustomImageScrooll(Owner).OptionsSelection.Opacity then
      DrawBitmap(Self.Canvas, iR, Bitmap, AbsoluteOpacity/2)
    else
      DrawBitmap(Self.Canvas, iR, Bitmap, AbsoluteOpacity);
    vIcon := TCustomImageScrooll(Owner).OptionsSelection.Icon;
    if not vIcon.IsEmpty then
    begin
      icR := iR;
      case TCustomImageScrooll(Owner).OptionsSelection.IconPosition of
        ipTopLeft:
        begin
          icR.Bottom := vIcon.Height;
          icR.Right := vIcon.Width;
        end;
        ipTopRight:
        begin
          icR.Bottom := icR.Height - vIcon.Height;
          icR.Left := icR.Width - vIcon.Width;
        end;
        ipBottomLeft:
        begin
          icR.Top := icR.Height - vIcon.Height;
          icR.Right := vIcon.Width;
        end;
        ipBottomRight:
        begin
          icR.Top := icR.Height - vIcon.Height;
          icR.Left := icR.Width - vIcon.Width;
        end;
        ipCenter:
        begin
          icR.Bottom := vIcon.Height;
          icR.Right := vIcon.Width;
          icR := RectCenter(icR, iR);
        end;
      end;
      DrawBitmap(Self.Canvas, icR, vIcon, AbsoluteOpacity);
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
      InflateRect(iR, -iR.Right * 0.1, - iR.Bottom * 0.1);
    InternalDrawSelectionImage;
  end else
    inherited Paint;
end;

procedure TBaseImageItem.SetSelected(const Value: Boolean);
var
  i : Integer;
begin
  if fSelected = Value then
    Exit;
  if Value and not TCustomImageScrooll(Owner).OptionsSelection.MultiSelect then
    TCustomImageScrooll(Owner).ClearSelection(self);
  fSelected := Value;
  i := TCustomImageScrooll(Owner).SelectedItems.IndexOf(self);
  if fSelected then
  begin
    if i = -1 then
      TCustomImageScrooll(Owner).SelectedItems.Add(self);
  end else
  begin
    if i <> -1 then
      TCustomImageScrooll(Owner).SelectedItems.Delete(i);
  end;
  if TCustomImageScrooll(Owner).ItemVisible(self) then
    Repaint;
end;

{ TImageItems }

constructor TImageItems.Create(const [weak]AScrool: TCustomImageScrooll);
begin
  FScrool := AScrool;
  inherited Create;
end;

function TImageItems.CreateItem<T>: T;
begin
  TBaseImageItem(result) := TBaseImageItemClass(T).Create(FScrool);
  TBaseImageItem(result).fList := self;
  TBaseImageItem(result).Align := TAlignLayout.None;
  self.Add(TBaseImageItem(result));
end;

procedure TImageItems.Notify(const Value: TBaseImageItem; Action: TCollectionNotification);
begin
  if Action = TCollectionNotification.cnRemoved then
    Value.DisposeOf;
  inherited;
  if Assigned(FScrool) and (not FScrool.IsUpdating) and FScrool.CanRepaint then
      FScrool.UpdatePictures;
end;

{ TSelectedImageItems }

procedure TSelectedImageItems.Notify(const Value: TBaseImageItem; Action: TCollectionNotification);
begin
  case Action of
    cnAdded:
      Value.Selected := True;
    cnRemoved,
    cnExtracted:
      Value.Selected := false;
  end;
  inherited;
end;

end.
