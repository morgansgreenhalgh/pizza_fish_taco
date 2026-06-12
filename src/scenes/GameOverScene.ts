import Phaser from 'phaser';
import { GAME_HEIGHT, GAME_WIDTH } from '../shared/constants';
import { ControllerInput } from '../input/ControllerInput';

export class GameOverScene extends Phaser.Scene {
  private controller?: ControllerInput;

  constructor() {
    super('GameOverScene');
  }

  create(data: { won?: boolean; score?: number }): void {
    this.add.rectangle(0, 0, GAME_WIDTH, GAME_HEIGHT, data.won ? 0x0e2316 : 0x1a0710).setOrigin(0);
    this.add.text(GAME_WIDTH / 2, 170, data.won ? 'SNACK CITY SAVED!' : 'PIZZA FISH TACO FELL', {
      fontFamily: 'monospace',
      fontSize: '42px',
      color: data.won ? '#69ff7b' : '#ff5555',
      stroke: '#000000',
      strokeThickness: 8,
    }).setOrigin(0.5);
    this.add.text(GAME_WIDTH / 2, 260, `Score ${data.score ?? 0}`, {
      fontFamily: 'monospace',
      fontSize: '28px',
      color: '#ffffff',
      stroke: '#000000',
      strokeThickness: 6,
    }).setOrigin(0.5);
    this.add.text(GAME_WIDTH / 2, 346, 'Press Enter or Start to return to menu', {
      fontFamily: 'monospace',
      fontSize: '22px',
      color: '#ffe964',
      stroke: '#000000',
      strokeThickness: 5,
    }).setOrigin(0.5);
    this.controller = new ControllerInput(this);
    this.input.keyboard?.once('keydown-ENTER', () => this.scene.start('MenuScene'));
  }

  update(): void {
    if (this.controller?.read().startPressed) {
      this.scene.start('MenuScene');
    }
  }
}
