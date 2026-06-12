import Phaser from 'phaser';

const DEADZONE = 0.28;

export type ControllerSnapshot = {
  connected: boolean;
  horizontal: number;
  jumpPressed: boolean;
  lightPressed: boolean;
  heavyPressed: boolean;
  specialPressed: boolean;
  startPressed: boolean;
};

type ButtonState = Record<number, boolean>;

export class ControllerInput {
  private readonly scene: Phaser.Scene;
  private previousButtons: ButtonState = {};

  constructor(scene: Phaser.Scene) {
    this.scene = scene;
    this.scene.input.gamepad?.once(Phaser.Input.Gamepad.Events.CONNECTED, () => {
      this.previousButtons = {};
    });
  }

  read(): ControllerSnapshot {
    const pad = this.scene.input.gamepad?.pad1;
    if (!pad) {
      this.previousButtons = {};
      return this.empty();
    }

    const currentButtons = this.readButtons(pad);
    const leftAxis = this.readAxis(pad, 0);
    const horizontal = this.resolveHorizontal(leftAxis, currentButtons);
    const snapshot: ControllerSnapshot = {
      connected: true,
      horizontal,
      jumpPressed: this.justPressed(0, currentButtons),
      lightPressed: this.justPressed(2, currentButtons),
      heavyPressed: this.justPressed(1, currentButtons),
      specialPressed: this.justPressed(3, currentButtons) || this.justPressed(5, currentButtons),
      startPressed: this.justPressed(9, currentButtons),
    };

    this.previousButtons = currentButtons;
    return snapshot;
  }

  private empty(): ControllerSnapshot {
    return {
      connected: false,
      horizontal: 0,
      jumpPressed: false,
      lightPressed: false,
      heavyPressed: false,
      specialPressed: false,
      startPressed: false,
    };
  }

  private readButtons(pad: Phaser.Input.Gamepad.Gamepad): ButtonState {
    const buttons: ButtonState = {};
    for (let index = 0; index < pad.buttons.length; index += 1) {
      buttons[index] = pad.buttons[index].pressed;
    }
    return buttons;
  }

  private readAxis(pad: Phaser.Input.Gamepad.Gamepad, index: number): number {
    const axis = pad.axes[index];
    if (!axis) {
      return 0;
    }
    const value = axis.getValue();
    return Math.abs(value) > DEADZONE ? value : 0;
  }

  private resolveHorizontal(axis: number, buttons: ButtonState): number {
    if (axis !== 0) {
      return Phaser.Math.Clamp(axis, -1, 1);
    }
    if (buttons[14]) {
      return -1;
    }
    if (buttons[15]) {
      return 1;
    }
    return 0;
  }

  private justPressed(index: number, buttons: ButtonState): boolean {
    return buttons[index] === true && this.previousButtons[index] !== true;
  }
}
