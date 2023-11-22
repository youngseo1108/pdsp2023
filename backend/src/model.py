from fastapi.encoders import jsonable_encoder
from pydantic import BaseModel
from typing import List

class Swiss(BaseModel):
  id: int
  Orig: int
  con1: int
  con2: int
  Dest: int
  op_flight1: int
  op_flight2: int
  op_flight3: int
  depDay: int
  elaptime: float
  detour: float
  arrDay: int
  stops: int
  paxe: float
  cluster: float
  TOT_pax: float
  market_share: float
  real_dist: float
  total_time: float
  connection_time: int
  dep_hour: int
  arr_hour: int
  def to_json(self):
    return jsonable_encoder(self, exclude_none=True)