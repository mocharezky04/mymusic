from fastapi import APIRouter

from ..models import RecommendationRequest, RecommendationResponse
from ..recommend import recommend

router = APIRouter(tags=["recommend"])


@router.post("/recommendations", response_model=RecommendationResponse)
async def recommendations(payload: RecommendationRequest) -> RecommendationResponse:
    return await recommend(payload)
