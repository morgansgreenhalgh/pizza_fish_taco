export type Facing = -1 | 1;

export type AttackKind = 'light1' | 'light2' | 'light3' | 'heavy' | 'special';

export type AttackConfig = {
  kind: AttackKind;
  damage: number;
  knockbackX: number;
  knockbackY: number;
  range: number;
  height: number;
  duration: number;
  recovery: number;
  specialCost?: number;
};

export type FighterStats = {
  health: number;
  maxHealth: number;
  damage: number;
  moveSpeed: number;
  scoreValue: number;
};
