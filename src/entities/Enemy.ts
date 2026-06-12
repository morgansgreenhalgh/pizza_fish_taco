import Phaser from 'phaser';
import { BaseFighter } from './BaseFighter';
import type { FighterStats } from '../shared/types';

export type EnemyKind = 'burger-grunt' | 'fry-goblin' | 'big-bad-burger';

const enemyStats: Record<EnemyKind, FighterStats> = {
  'burger-grunt': {
    health: 42,
    maxHealth: 42,
    damage: 10,
    moveSpeed: 95,
    scoreValue: 100,
  },
  'fry-goblin': {
    health: 34,
    maxHealth: 34,
    damage: 8,
    moveSpeed: 135,
    scoreValue: 125,
  },
  'big-bad-burger': {
    health: 260,
    maxHealth: 260,
    damage: 18,
    moveSpeed: 82,
    scoreValue: 1000,
  },
};

export class Enemy extends BaseFighter {
  readonly kind: EnemyKind;
  readonly displayName: string;
  attackCooldownUntil = 0;
  isBoss: boolean;
  private attackWindup = false;

  constructor(scene: Phaser.Scene, x: number, y: number, kind: EnemyKind) {
    super(scene, x, y, kind, enemyStats[kind]);
    this.kind = kind;
    this.isBoss = kind === 'big-bad-burger';
    this.displayName = this.isBoss ? 'Big Bad Burger' : kind === 'fry-goblin' ? 'Fry Goblin' : 'Burger Grunt';
    this.body.setSize(this.isBoss ? 104 : 56, this.isBoss ? 112 : 64);
    this.body.setOffset(this.isBoss ? 20 : 10, this.isBoss ? 18 : 16);
    this.setDepth(this.isBoss ? 11 : 10);
  }

  updateAi(player: Phaser.Physics.Arcade.Sprite): boolean {
    if (this.isDead || this.isHurt || this.attackWindup) {
      return false;
    }

    const distanceX = player.x - this.x;
    this.facing = distanceX >= 0 ? 1 : -1;
    this.setFlipX(this.facing < 0);
    const attackRange = this.isBoss ? 112 : 56;

    if (Math.abs(distanceX) > attackRange) {
      this.setVelocityX(Math.sign(distanceX) * this.moveSpeed);
      return false;
    }

    this.setVelocityX(0);
    if (this.scene.time.now >= this.attackCooldownUntil) {
      this.attackWindup = true;
      this.setTint(this.isBoss ? 0xff534a : 0xffcc44);
      this.scene.time.delayedCall(this.isBoss ? 420 : 260, () => {
        this.attackWindup = false;
        this.clearTint();
      });
      this.attackCooldownUntil = this.scene.time.now + (this.isBoss ? 1450 : 950);
      return true;
    }

    return false;
  }
}
